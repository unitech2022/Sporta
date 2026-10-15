using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.DTOs;
using SportaApis.Enums;

namespace SportaApis.Services;

/// <summary>
/// البطولات الاستعراضية (<see cref="Models.Tournament"/>): قائمة للعرض فقط،
/// منفصلة تماماً عن البطولة الإقصائية القابلة للعب (<see cref="TournamentService"/>).
/// </summary>
public interface IShowcaseTournamentService
{
    Task<List<ShowcaseTournamentDto>> GetAllAsync();
}

public class ShowcaseTournamentService : IShowcaseTournamentService
{
    private readonly AppDbContext _db;

    public ShowcaseTournamentService(AppDbContext db) => _db = db;

    public async Task<List<ShowcaseTournamentDto>> GetAllAsync() =>
        await _db.Tournaments
            .OrderBy(t => t.StartDate)
            .Select(t => new ShowcaseTournamentDto
            {
                Id = t.Id,
                Name = t.Name,
                StartDate = t.StartDate,
                EndDate = t.EndDate,
                Location = t.Location,
                PrizeLabel = t.PrizeLabel,
                PrizeAmount = t.PrizeAmount,
                Scope = t.Scope == TournamentScope.Local ? "local" : "international",
            })
            .ToListAsync();
}
