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
    public class SupportTicketService : BaseService<SupportTicketResponse, SupportTicketSearchObject, SupportTicket>, ISupportTicketService
    {
        public SupportTicketService(QuickWorkDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        public override async Task<PagedResult<SupportTicketResponse>> GetAsync(SupportTicketSearchObject search)
        {
            var query = _context.SupportTickets.AsQueryable();

            if (search.UserId.HasValue)
            {
                query = query.Where(t => t.UserId == search.UserId.Value);
            }

            if (!string.IsNullOrEmpty(search.Status))
            {
                query = query.Where(t => t.Status == search.Status);
            }

            if (!string.IsNullOrEmpty(search.Priority))
            {
                query = query.Where(t => t.Priority == search.Priority);
            }

            if (!string.IsNullOrEmpty(search.Category))
            {
                query = query.Where(t => t.Category == search.Category);
            }

            if (search.IsActive.HasValue)
            {
                query = query.Where(t => t.IsActive == search.IsActive.Value);
            }
            else
            {
                // By default only return active (non-deleted) tickets.
                query = query.Where(t => t.IsActive);
            }

            query = query
                .Include(t => t.User)
                .OrderByDescending(t => t.CreatedAt);

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

            var tickets = await query.ToListAsync();
            return new PagedResult<SupportTicketResponse>
            {
                Items = tickets.Select(MapToResponse).ToList(),
                TotalCount = totalCount
            };
        }

        public override async Task<SupportTicketResponse?> GetByIdAsync(int id)
        {
            var ticket = await _context.SupportTickets
                .Include(t => t.User)
                .FirstOrDefaultAsync(t => t.Id == id && t.IsActive);

            if (ticket == null)
                return null;

            return MapToResponse(ticket);
        }

        public async Task<SupportTicketResponse> CreateAsync(SupportTicketUpsertRequest request)
        {
            var now = DateTime.UtcNow;
            var ticket = new SupportTicket
            {
                UserId = request.UserId,
                Subject = request.Subject,
                Message = request.Message,
                Category = request.Category,
                Priority = request.Priority,
                Status = "Open",
                CreatedAt = now,
                UpdatedAt = now,
                IsActive = true
            };

            _context.SupportTickets.Add(ticket);
            await _context.SaveChangesAsync();

            return await GetByIdAsync(ticket.Id) ?? throw new InvalidOperationException("Failed to create support ticket.");
        }

        public async Task<SupportTicketResponse?> ReplyAsync(int id, SupportTicketReplyRequest request)
        {
            var ticket = await _context.SupportTickets
                .Include(t => t.User)
                .FirstOrDefaultAsync(t => t.Id == id && t.IsActive);

            if (ticket == null)
                return null;

            ticket.AdminReply = request.AdminReply;

            // Advance the lifecycle: honor an explicit status, otherwise move an
            // open/working ticket to Resolved once an administrator replies.
            if (!string.IsNullOrEmpty(request.Status))
            {
                ticket.Status = request.Status;
            }
            else if (ticket.Status != "Closed")
            {
                ticket.Status = "Resolved";
            }

            ticket.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
            return MapToResponse(ticket);
        }

        public async Task<SupportTicketResponse?> UpdateStatusAsync(int id, string status)
        {
            var ticket = await _context.SupportTickets
                .Include(t => t.User)
                .FirstOrDefaultAsync(t => t.Id == id && t.IsActive);

            if (ticket == null)
                return null;

            ticket.Status = status;
            ticket.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
            return MapToResponse(ticket);
        }

        public async Task<bool> DeleteAsync(int id)
        {
            var ticket = await _context.SupportTickets.FindAsync(id);
            if (ticket == null)
                return false;

            // Soft delete: keep the record for audit but hide it from lists.
            ticket.IsActive = false;
            ticket.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
            return true;
        }

        protected override SupportTicketResponse MapToResponse(SupportTicket ticket)
        {
            return new SupportTicketResponse
            {
                Id = ticket.Id,
                UserId = ticket.UserId,
                UserName = ticket.User != null ? $"{ticket.User.FirstName} {ticket.User.LastName}" : string.Empty,
                UserEmail = ticket.User?.Email ?? string.Empty,
                Subject = ticket.Subject,
                Message = ticket.Message,
                Category = ticket.Category,
                Priority = ticket.Priority,
                Status = ticket.Status,
                AdminReply = ticket.AdminReply,
                CreatedAt = ticket.CreatedAt,
                UpdatedAt = ticket.UpdatedAt,
                IsActive = ticket.IsActive
            };
        }
    }
}
