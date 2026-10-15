using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.DTOs;
using SportaApis.Models;

namespace SportaApis.Services;

public class CoachSpecializationService : ICoachSpecializationService
{
    private readonly AppDbContext _db;

    public CoachSpecializationService(AppDbContext db) => _db = db;

    public async Task<List<CoachSpecializationDto>> GetActiveAsync()
    {
        var items = await _db.CoachSpecializations
            .Where(s => s.IsActive)
            .OrderBy(s => s.SortOrder)
            .ThenBy(s => s.Id)
            .ToListAsync();
        return items.Select(ToDto).ToList();
    }

    public async Task<List<CoachSpecializationDto>> GetAllAsync()
    {
        var items = await _db.CoachSpecializations
            .OrderBy(s => s.SortOrder)
            .ThenBy(s => s.Id)
            .ToListAsync();
        return items.Select(ToDto).ToList();
    }

    public async Task<CoachSpecializationDto> CreateAsync(SaveCoachSpecializationRequest req)
    {
        var spec = new CoachSpecialization();
        Apply(spec, req);
        _db.CoachSpecializations.Add(spec);
        await _db.SaveChangesAsync();
        return ToDto(spec);
    }

    public async Task<CoachSpecializationDto> UpdateAsync(int id, SaveCoachSpecializationRequest req)
    {
        var spec = await _db.CoachSpecializations.FirstOrDefaultAsync(s => s.Id == id)
            ?? throw new AuthException(
                "Specialization not found", "التخصص غير موجود", "SPECIALIZATION_NOT_FOUND");
        Apply(spec, req);
        spec.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        return ToDto(spec);
    }

    public async Task DeleteAsync(int id)
    {
        var spec = await _db.CoachSpecializations.FirstOrDefaultAsync(s => s.Id == id)
            ?? throw new AuthException(
                "Specialization not found", "التخصص غير موجود", "SPECIALIZATION_NOT_FOUND");
        _db.CoachSpecializations.Remove(spec);
        await _db.SaveChangesAsync();
    }

    private static void Apply(CoachSpecialization spec, SaveCoachSpecializationRequest req)
    {
        spec.NameAr = req.NameAr.Trim();
        spec.NameEn = req.NameEn.Trim();
        spec.IsActive = req.IsActive;
        spec.SortOrder = req.SortOrder;
    }

    private static CoachSpecializationDto ToDto(CoachSpecialization s) => new()
    {
        Id = s.Id,
        NameAr = s.NameAr,
        NameEn = s.NameEn,
        IsActive = s.IsActive,
        SortOrder = s.SortOrder,
    };
}
