using Xunit;
using PromotionWeb.Services;

namespace PromotionWeb.Tests;

public class DeliveryApiTokenStoreTests
{
    [Fact]
    public void CreateToken_ShouldReturnValidTokenAndSession()
    {
        // Arrange
        var tokenStore = new DeliveryApiTokenStore();
        int userId = 42;
        string name = "Karim Deliveryman";
        string phone = "01700000000";
        string role = "DeliveryMan";

        // Act
        var token = tokenStore.Create(userId, name, phone, role);
        var session = tokenStore.Get($"Bearer {token}");

        // Assert
        Assert.NotNull(token);
        Assert.NotEmpty(token);
        Assert.NotNull(session);
        Assert.Equal(userId, session.UserId);
        Assert.Equal(name, session.Name);
        Assert.Equal(phone, session.Phone);
        Assert.Equal(role, session.Role);
    }

    [Fact]
    public void GetSession_WithInvalidHeader_ShouldReturnNull()
    {
        // Arrange
        var tokenStore = new DeliveryApiTokenStore();

        // Act & Assert
        Assert.Null(tokenStore.Get(null));
        Assert.Null(tokenStore.Get(""));
        Assert.Null(tokenStore.Get("Basic 12345"));
        Assert.Null(tokenStore.Get("Bearer invalid_token_here"));
    }

    [Fact]
    public void RevokeToken_ShouldRemoveSessionFromStore()
    {
        // Arrange
        var tokenStore = new DeliveryApiTokenStore();
        var token = tokenStore.Create(1, "Test User", "01800000000", "DeliveryMan");

        // Act
        Assert.NotNull(tokenStore.GetToken(token));
        tokenStore.Revoke($"Bearer {token}");

        // Assert
        Assert.Null(tokenStore.GetToken(token));
        Assert.Null(tokenStore.Get($"Bearer {token}"));
    }
}
