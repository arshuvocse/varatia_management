using System.Globalization;
using Dapper;
using OrderProcessAPI.Configuration;
using OrderProcessAPI.Contracts;

namespace OrderProcessAPI.Services;

public sealed class TenantPaymentService : ITenantPaymentService
{
    private readonly SqlConnectionFactory _connectionFactory;
    private readonly IMessageRealtimeService _messageRealtimeService;

    public TenantPaymentService(
        SqlConnectionFactory connectionFactory,
        IMessageRealtimeService messageRealtimeService)
    {
        _connectionFactory = connectionFactory;
        _messageRealtimeService = messageRealtimeService;
    }

    public async Task<GetRentPaymentsResponse> GetRentPaymentsAsync(
        string userId,
        CancellationToken cancellationToken = default)
    {
        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var payments = await connection.QueryAsync<RentPaymentDto>(
            new CommandDefinition(
                "sp_GetRentPaymentsByOwner",
                new { UserId = userId },
                commandType: System.Data.CommandType.StoredProcedure,
                cancellationToken: cancellationToken));

        return new GetRentPaymentsResponse
        {
            Payments = payments.ToList()
        };
    }

    public async Task<ConfirmTenantPaymentResponse> ConfirmPaymentAsync(
        ConfirmTenantPaymentRequest request,
        CancellationToken cancellationToken = default)
    {
        var tenantId = request.TenantId.Trim();
        var monthLabel = request.MonthLabel.Trim();
        var paymentMethod = request.PaymentMethod.Trim();
        var paymentTypes = request.PaymentTypes
            .Where(type => !string.IsNullOrWhiteSpace(type))
            .Select(type => type.Trim())
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToArray();

        ValidateRequest(tenantId, monthLabel, request.Amount, paymentMethod, paymentTypes);

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await using var transaction = await connection.BeginTransactionAsync(
            cancellationToken);

        try
        {
            var tenant = await connection.QuerySingleOrDefaultAsync<TenantPaymentLookup>(
                new CommandDefinition(
                    """
                    SELECT
                        t.Id,
                        t.Name,
                        t.Phone,
                        t.Nid,
                        t.PropertyId,
                        p.Name AS PropertyName,
                        p.MonthlyRent
                    FROM dbo.Tenants t
                    INNER JOIN dbo.Properties p ON p.Id = t.PropertyId
                    WHERE t.Id = @TenantId;
                    """,
                    new { TenantId = tenantId },
                    transaction: transaction,
                    cancellationToken: cancellationToken));

            if (tenant is null)
            {
                throw new TenantPaymentNotFoundException("Tenant was not found.");
            }

            if (string.IsNullOrWhiteSpace(tenant.PropertyId))
            {
                throw new TenantPaymentValidationException(
                    "Tenant does not have an assigned property.");
            }

            var existingPayment = await connection.QuerySingleOrDefaultAsync<PaymentLookup>(
                new CommandDefinition(
                    """
                    SELECT TOP (1) Id
                    FROM dbo.RentPayments
                    WHERE PropertyId = @PropertyId
                      AND MonthLabel = @MonthLabel
                    ORDER BY Id DESC;
                    """,
                    new
                    {
                        tenant.PropertyId,
                        MonthLabel = monthLabel,
                    },
                    transaction: transaction,
                    cancellationToken: cancellationToken));

            var paidOn = DateTime.Now;
            var dueAmount = Math.Max(tenant.MonthlyRent - request.Amount, 0);
            var paymentTypesLabel = string.Join(", ", paymentTypes);
            var notificationSubtitle =
                $"{monthLabel} payment for {tenant.PropertyName} was confirmed by {tenant.Name}.";
            var messageText =
                $"{monthLabel} payment confirmed via {paymentMethod} ({paymentTypesLabel}).";
            var timeLabel = paidOn.ToString("hh:mm tt", CultureInfo.InvariantCulture);
            CommunicationMessageDto? createdMessage = null;

            if (existingPayment is null)
            {
                await connection.ExecuteAsync(
                    new CommandDefinition(
                        """
                        INSERT INTO dbo.RentPayments
                        (
                            PropertyId,
                            TenantName,
                            MonthLabel,
                            Amount,
                            Status,
                            PaidOn
                        )
                        VALUES
                        (
                            @PropertyId,
                            @TenantName,
                            @MonthLabel,
                            @Amount,
                            'paid',
                            @PaidOn
                        );
                        """,
                        new
                        {
                            tenant.PropertyId,
                            TenantName = tenant.Name,
                            MonthLabel = monthLabel,
                            Amount = request.Amount,
                            PaidOn = paidOn,
                        },
                        transaction: transaction,
                        cancellationToken: cancellationToken));
            }
            else
            {
                await connection.ExecuteAsync(
                    new CommandDefinition(
                        """
                        UPDATE dbo.RentPayments
                        SET
                            TenantName = @TenantName,
                            Amount = @Amount,
                            Status = 'paid',
                            PaidOn = @PaidOn
                        WHERE Id = @PaymentId;
                        """,
                        new
                        {
                            PaymentId = existingPayment.Id,
                            TenantName = tenant.Name,
                            Amount = request.Amount,
                            PaidOn = paidOn,
                        },
                        transaction: transaction,
                        cancellationToken: cancellationToken));
            }

            await connection.ExecuteAsync(
                new CommandDefinition(
                    """
                    UPDATE dbo.Properties
                    SET
                        Status = 'rented',
                        TenantName = @TenantName,
                        DueAmount = @DueAmount
                    WHERE Id = @PropertyId;
                    """,
                    new
                    {
                        TenantName = tenant.Name,
                        DueAmount = dueAmount,
                        tenant.PropertyId,
                    },
                    transaction: transaction,
                    cancellationToken: cancellationToken));

            var messageId = await connection.ExecuteScalarAsync<int>(
                new CommandDefinition(
                    """
                    INSERT INTO dbo.Activities (Title, Subtitle, TimeLabel)
                    VALUES (@Title, @Subtitle, 'Today');

                    INSERT INTO dbo.Notifications (Title, Subtitle, CreatedAt, IsUnread)
                    VALUES (@NotificationTitle, @NotificationSubtitle, @CreatedAt, 1);

                    INSERT INTO dbo.Messages (Sender, Message, PropertyName, TimeLabel)
                    OUTPUT INSERTED.Id
                    VALUES (@Sender, @Message, @PropertyName, @TimeLabel);
                    """,
                    new
                    {
                        Title = "Rent payment confirmed",
                        Subtitle = $"{tenant.Name} confirmed rent payment for {tenant.PropertyName}.",
                        NotificationTitle = "Rent payment confirmed",
                        NotificationSubtitle = notificationSubtitle,
                        CreatedAt = paidOn,
                        Sender = tenant.Name,
                        Message = messageText,
                        tenant.PropertyName,
                        TimeLabel = timeLabel,
                    },
                    transaction: transaction,
                    cancellationToken: cancellationToken));

            createdMessage = new CommunicationMessageDto
            {
                Id = messageId,
                Sender = tenant.Name,
                Message = messageText,
                PropertyName = tenant.PropertyName,
                TimeLabel = timeLabel,
            };

            await transaction.CommitAsync(cancellationToken);

            if (createdMessage is not null)
            {
                await _messageRealtimeService.BroadcastMessageCreatedAsync(createdMessage);
            }

            return new ConfirmTenantPaymentResponse
            {
                Tenant = new TenantProfileDto
                {
                    Id = tenant.Id,
                    Name = tenant.Name,
                    Phone = tenant.Phone,
                    Nid = tenant.Nid,
                    PropertyName = tenant.PropertyName,
                },
                Payment = new RentPaymentDto
                {
                    PropertyName = tenant.PropertyName,
                    TenantName = tenant.Name,
                    MonthLabel = monthLabel,
                    Amount = request.Amount,
                    Status = "paid",
                    PaidOn = paidOn,
                },
                PropertyId = tenant.PropertyId,
                PropertyName = tenant.PropertyName,
                DueAmount = dueAmount,
                Message = "Payment confirmed successfully.",
            };
        }
        catch
        {
            await transaction.RollbackAsync(cancellationToken);
            throw;
        }
    }

    private static void ValidateRequest(
        string tenantId,
        string monthLabel,
        int amount,
        string paymentMethod,
        IReadOnlyCollection<string> paymentTypes)
    {
        if (string.IsNullOrWhiteSpace(tenantId))
        {
            throw new TenantPaymentValidationException("Tenant id is required.");
        }

        if (string.IsNullOrWhiteSpace(monthLabel))
        {
            throw new TenantPaymentValidationException("Month label is required.");
        }

        if (amount <= 0)
        {
            throw new TenantPaymentValidationException("Amount must be greater than zero.");
        }

        if (string.IsNullOrWhiteSpace(paymentMethod))
        {
            throw new TenantPaymentValidationException("Payment method is required.");
        }

        if (paymentTypes.Count == 0)
        {
            throw new TenantPaymentValidationException(
                "At least one payment type is required.");
        }
    }

    private sealed class TenantPaymentLookup
    {
        public string Id { get; init; } = string.Empty;
        public string Name { get; init; } = string.Empty;
        public string Phone { get; init; } = string.Empty;
        public string Nid { get; init; } = string.Empty;
        public string PropertyId { get; init; } = string.Empty;
        public string PropertyName { get; init; } = string.Empty;
        public int MonthlyRent { get; init; }
    }

    private sealed class PaymentLookup
    {
        public int Id { get; init; }
    }
}

public sealed class TenantPaymentValidationException : Exception
{
    public TenantPaymentValidationException(string message)
        : base(message)
    {
    }
}

public sealed class TenantPaymentNotFoundException : Exception
{
    public TenantPaymentNotFoundException(string message)
        : base(message)
    {
    }
}
