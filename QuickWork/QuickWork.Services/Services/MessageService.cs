using QuickWork.Services.Database;
using Microsoft.EntityFrameworkCore;
using System;
using System.Linq;
using System.Threading.Tasks;
using QuickWork.Model.Requests;
using QuickWork.Model.Responses;
using QuickWork.Model.SearchObjects;
using QuickWork.Services.Interfaces;
using MapsterMapper;

namespace QuickWork.Services.Services
{
    public class MessageService : BaseService<MessageResponse, MessageSearchObject, Message>, IMessageService
    {
        public MessageService(QuickWorkDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        public override async Task<PagedResult<MessageResponse>> GetAsync(MessageSearchObject search)
        {
            var query = _context.Messages.AsQueryable();

            if (search.JobPostingId.HasValue)
            {
                query = query.Where(m => m.JobPostingId == search.JobPostingId.Value);
            }

            if (search.SenderUserId.HasValue)
            {
                query = query.Where(m => m.SenderUserId == search.SenderUserId.Value);
            }

            if (search.ReceiverUserId.HasValue)
            {
                query = query.Where(m => m.ReceiverUserId == search.ReceiverUserId.Value);
            }

            if (search.IsRead.HasValue)
            {
                query = query.Where(m => m.IsRead == search.IsRead.Value);
            }

            query = query
                .Include(m => m.JobPosting)
                .Include(m => m.SenderUser)
                .Include(m => m.ReceiverUser)
                .OrderByDescending(m => m.SentAt);

            int? totalCount = null;
            if (search.IncludeTotalCount)
            {
                totalCount = await query.CountAsync();
            }

            if (!search.RetrieveAll)
            {
                if (search.Page.HasValue)
                {
                    query = query.Skip(search.Page.Value * search.PageSize.Value);
                }
                if (search.PageSize.HasValue)
                {
                    query = query.Take(search.PageSize.Value);
                }
            }

            var messages = await query.ToListAsync();
            return new PagedResult<MessageResponse>
            {
                Items = messages.Select(MapToResponse).ToList(),
                TotalCount = totalCount
            };
        }

        public override async Task<MessageResponse?> GetByIdAsync(int id)
        {
            var message = await _context.Messages
                .Include(m => m.JobPosting)
                .Include(m => m.SenderUser)
                .Include(m => m.ReceiverUser)
                .FirstOrDefaultAsync(m => m.Id == id);

            if (message == null)
                return null;

            return MapToResponse(message);
        }

        public async Task<MessageResponse> CreateAsync(MessageUpsertRequest request, int senderUserId)
        {
            var message = new Message
            {
                JobPostingId = request.JobPostingId,
                SenderUserId = senderUserId,
                ReceiverUserId = request.ReceiverUserId,
                Content = request.Content,
                SentAt = DateTime.UtcNow,
                IsRead = false
            };

            _context.Messages.Add(message);
            await _context.SaveChangesAsync();

            return await GetByIdAsync(message.Id) ?? throw new InvalidOperationException("Failed to create message.");
        }

        public async Task<MessageResponse?> MarkAsReadAsync(int id)
        {
            var message = await _context.Messages.FindAsync(id);
            if (message == null)
                return null;

            message.IsRead = true;
            message.ReadAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();
            return await GetByIdAsync(message.Id);
        }

        public async Task<bool> DeleteAsync(int id)
        {
            var message = await _context.Messages.FindAsync(id);
            if (message == null)
                return false;

            _context.Messages.Remove(message);
            await _context.SaveChangesAsync();
            return true;
        }

        protected override MessageResponse MapToResponse(Message message)
        {
            return new MessageResponse
            {
                Id = message.Id,
                JobPostingId = message.JobPostingId,
                JobPostingTitle = message.JobPosting?.Title ?? string.Empty,
                SenderUserId = message.SenderUserId,
                SenderUserName = message.SenderUser != null ? $"{message.SenderUser.FirstName} {message.SenderUser.LastName}" : string.Empty,
                ReceiverUserId = message.ReceiverUserId,
                ReceiverUserName = message.ReceiverUser != null ? $"{message.ReceiverUser.FirstName} {message.ReceiverUser.LastName}" : string.Empty,
                Content = message.Content,
                SentAt = message.SentAt,
                IsRead = message.IsRead,
                ReadAt = message.ReadAt
            };
        }
    }
}
