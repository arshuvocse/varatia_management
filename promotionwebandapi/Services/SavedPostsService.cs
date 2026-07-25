using Dapper;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Threading.Tasks;

namespace OrderProcessAPI.Services
{
    public class SavedPostsService : ISavedPostsService
    {
        private readonly string _connectionString;

        public SavedPostsService(IConfiguration configuration)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new InvalidOperationException("Connection string 'DefaultConnection' is not configured.");
        }

        public async Task<ToggleSavedPostResult> ToggleSavedPostAsync(string userId, int postId, string postType)
        {
            using (var connection = new SqlConnection(_connectionString))
            {
                var parameters = new DynamicParameters();
                parameters.Add("@UserId", userId);
                parameters.Add("@PostId", postId);
                parameters.Add("@PostType", postType);

                var isSaved = await connection.QuerySingleOrDefaultAsync<int>(
                    "sp_ToggleSavedPost", 
                    parameters, 
                    commandType: CommandType.StoredProcedure);

                return new ToggleSavedPostResult { IsSaved = isSaved == 1 };
            }
        }

        public async Task<List<SavedPostDto>> GetSavedPostsAsync(string userId)
        {
            using (var connection = new SqlConnection(_connectionString))
            {
                var parameters = new DynamicParameters();
                parameters.Add("@UserId", userId);

                var result = await connection.QueryAsync<SavedPostDto>(
                    "sp_GetSavedPosts", 
                    parameters, 
                    commandType: CommandType.StoredProcedure);

                return result.ToList();
            }
        }
    }
}
