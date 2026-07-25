using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace OrderProcessAPI.Services
{
    public class SavedPostDto
    {
        public int Id { get; set; }
        public int PostId { get; set; }
        public string PostType { get; set; } = string.Empty;
        public DateTime SavedAt { get; set; }
    }

    public class ToggleSavedPostResult
    {
        public bool IsSaved { get; set; }
    }

    public interface ISavedPostsService
    {
        Task<ToggleSavedPostResult> ToggleSavedPostAsync(string userId, int postId, string postType);
        Task<List<SavedPostDto>> GetSavedPostsAsync(string userId);
    }
}
