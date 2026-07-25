using Microsoft.Data.SqlClient;
using PromotionWeb.Models;
using System;
using System.Collections.Generic;
using System.Data;

namespace PromotionWeb.Services;

public sealed class ShopkeeperExpenseStore(IConfiguration configuration)
{
    private readonly string _connectionString = configuration.GetConnectionString("DefaultConnection")
        ?? throw new InvalidOperationException("DefaultConnection connection string is missing.");

    private void EnsureExpenseTablesExist()
    {
        using var connection = new SqlConnection(_connectionString);
        connection.Open();

        const string createTypesTableSql = """
            IF OBJECT_ID(N'dbo.tbl_ExpenseTypes', N'U') IS NULL
            BEGIN
                CREATE TABLE dbo.tbl_ExpenseTypes
                (
                    Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tbl_ExpenseTypes PRIMARY KEY,
                    ShopkeeperId INT NOT NULL,
                    Name NVARCHAR(100) NOT NULL,
                    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_tbl_ExpenseTypes_CreatedAt DEFAULT (SYSUTCDATETIME()),
                    CONSTRAINT FK_tbl_ExpenseTypes_tbl_Shopkeepers FOREIGN KEY (ShopkeeperId) REFERENCES dbo.tbl_Shopkeepers(Id),
                    CONSTRAINT UQ_tbl_ExpenseTypes_Shopkeeper_Name UNIQUE (ShopkeeperId, Name)
                );
            END
            """;

        using (var command = new SqlCommand(createTypesTableSql, connection))
        {
            command.ExecuteNonQuery();
        }

        const string createExpensesTableSql = """
            IF OBJECT_ID(N'dbo.tbl_Expenses', N'U') IS NULL
            BEGIN
                CREATE TABLE dbo.tbl_Expenses
                (
                    Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tbl_Expenses PRIMARY KEY,
                    ShopkeeperId INT NOT NULL,
                    ExpenseTypeId INT NOT NULL,
                    Amount DECIMAL(18,2) NOT NULL,
                    ExpenseDate DATE NOT NULL,
                    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_tbl_Expenses_CreatedAt DEFAULT (SYSUTCDATETIME()),
                    CONSTRAINT FK_tbl_Expenses_tbl_Shopkeepers FOREIGN KEY (ShopkeeperId) REFERENCES dbo.tbl_Shopkeepers(Id),
                    CONSTRAINT FK_tbl_Expenses_tbl_ExpenseTypes FOREIGN KEY (ExpenseTypeId) REFERENCES dbo.tbl_ExpenseTypes(Id)
                );
            END
            """;

        using (var command = new SqlCommand(createExpensesTableSql, connection))
        {
            command.ExecuteNonQuery();
        }
    }

    private void EnsureDefaultExpenseTypes(int shopkeeperId)
    {
        EnsureExpenseTablesExist();

        using var connection = new SqlConnection(_connectionString);
        connection.Open();

        const string checkSql = "SELECT COUNT(1) FROM dbo.tbl_ExpenseTypes WHERE ShopkeeperId = @ShopkeeperId;";
        using (var checkCmd = new SqlCommand(checkSql, connection))
        {
            checkCmd.Parameters.AddWithValue("@ShopkeeperId", shopkeeperId);
            var count = (int)(checkCmd.ExecuteScalar() ?? 0);
            if (count > 0)
            {
                return;
            }
        }

        const string insertSql = """
            INSERT INTO dbo.tbl_ExpenseTypes (ShopkeeperId, Name)
            VALUES 
                (@ShopkeeperId, N'Rent (ভাড়া)'),
                (@ShopkeeperId, N'Utility Bills (ইউটিলিটি বিল)'),
                (@ShopkeeperId, N'Salary (বেতন)'),
                (@ShopkeeperId, N'Others (অন্যান্য)');
            """;

        using (var insertCmd = new SqlCommand(insertSql, connection))
        {
            insertCmd.Parameters.AddWithValue("@ShopkeeperId", shopkeeperId);
            insertCmd.ExecuteNonQuery();
        }
    }

    public IReadOnlyList<ShopkeeperExpenseTypeViewModel> GetExpenseTypes(int shopkeeperId)
    {
        EnsureDefaultExpenseTypes(shopkeeperId);

        using var connection = new SqlConnection(_connectionString);
        connection.Open();

        const string sql = "SELECT Id, Name FROM dbo.tbl_ExpenseTypes WHERE ShopkeeperId = @ShopkeeperId ORDER BY Name;";
        using var command = new SqlCommand(sql, connection);
        command.Parameters.AddWithValue("@ShopkeeperId", shopkeeperId);

        using var reader = command.ExecuteReader();
        var list = new List<ShopkeeperExpenseTypeViewModel>();
        while (reader.Read())
        {
            list.Add(new ShopkeeperExpenseTypeViewModel
            {
                Id = reader.GetInt32(reader.GetOrdinal("Id")),
                Name = reader.GetString(reader.GetOrdinal("Name"))
            });
        }
        return list;
    }

    public void AddExpenseType(int shopkeeperId, string name)
    {
        EnsureExpenseTablesExist();

        using var connection = new SqlConnection(_connectionString);
        connection.Open();

        const string checkSql = "SELECT COUNT(1) FROM dbo.tbl_ExpenseTypes WHERE ShopkeeperId = @ShopkeeperId AND Name = @Name;";
        using (var checkCmd = new SqlCommand(checkSql, connection))
        {
            checkCmd.Parameters.AddWithValue("@ShopkeeperId", shopkeeperId);
            checkCmd.Parameters.AddWithValue("@Name", name.Trim());
            var count = (int)(checkCmd.ExecuteScalar() ?? 0);
            if (count > 0)
            {
                throw new InvalidOperationException("এই Expense Type ইতিমধ্যে যোগ করা হয়েছে।");
            }
        }

        const string insertSql = "INSERT INTO dbo.tbl_ExpenseTypes (ShopkeeperId, Name) VALUES (@ShopkeeperId, @Name);";
        using var command = new SqlCommand(insertSql, connection);
        command.Parameters.AddWithValue("@ShopkeeperId", shopkeeperId);
        command.Parameters.AddWithValue("@Name", name.Trim());
        command.ExecuteNonQuery();
    }

    public IReadOnlyList<ShopkeeperExpenseViewModel> GetExpenses(int shopkeeperId)
    {
        EnsureExpenseTablesExist();

        using var connection = new SqlConnection(_connectionString);
        connection.Open();

        const string sql = """
            SELECT 
                e.Id,
                e.ExpenseTypeId,
                t.Name AS ExpenseTypeName,
                e.Amount,
                e.ExpenseDate
            FROM dbo.tbl_Expenses AS e
            INNER JOIN dbo.tbl_ExpenseTypes AS t ON t.Id = e.ExpenseTypeId
            WHERE e.ShopkeeperId = @ShopkeeperId
            ORDER BY e.ExpenseDate DESC, e.Id DESC;
            """;

        using var command = new SqlCommand(sql, connection);
        command.Parameters.AddWithValue("@ShopkeeperId", shopkeeperId);

        using var reader = command.ExecuteReader();
        var list = new List<ShopkeeperExpenseViewModel>();
        while (reader.Read())
        {
            list.Add(new ShopkeeperExpenseViewModel
            {
                Id = reader.GetInt32(reader.GetOrdinal("Id")),
                ExpenseTypeId = reader.GetInt32(reader.GetOrdinal("ExpenseTypeId")),
                ExpenseTypeName = reader.GetString(reader.GetOrdinal("ExpenseTypeName")),
                Amount = reader.GetDecimal(reader.GetOrdinal("Amount")),
                ExpenseDate = reader.GetDateTime(reader.GetOrdinal("ExpenseDate"))
            });
        }
        return list;
    }

    public void AddExpense(int shopkeeperId, ExpenseInputModel input)
    {
        EnsureExpenseTablesExist();

        using var connection = new SqlConnection(_connectionString);
        connection.Open();

        const string checkSql = "SELECT COUNT(1) FROM dbo.tbl_ExpenseTypes WHERE Id = @ExpenseTypeId AND ShopkeeperId = @ShopkeeperId;";
        using (var checkCmd = new SqlCommand(checkSql, connection))
        {
            checkCmd.Parameters.AddWithValue("@ExpenseTypeId", input.ExpenseTypeId);
            checkCmd.Parameters.AddWithValue("@ShopkeeperId", shopkeeperId);
            var count = (int)(checkCmd.ExecuteScalar() ?? 0);
            if (count == 0)
            {
                throw new InvalidOperationException("নির্বাচিত Expense Type সঠিক নয়।");
            }
        }

        const string insertSql = """
            INSERT INTO dbo.tbl_Expenses (ShopkeeperId, ExpenseTypeId, Amount, ExpenseDate)
            VALUES (@ShopkeeperId, @ExpenseTypeId, @Amount, @ExpenseDate);
            """;
        using var command = new SqlCommand(insertSql, connection);
        command.Parameters.AddWithValue("@ShopkeeperId", shopkeeperId);
        command.Parameters.AddWithValue("@ExpenseTypeId", input.ExpenseTypeId);
        command.Parameters.AddWithValue("@Amount", input.Amount);
        command.Parameters.AddWithValue("@ExpenseDate", input.ExpenseDate.Date);
        command.ExecuteNonQuery();
    }
}
