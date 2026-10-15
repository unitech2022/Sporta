namespace SportaApis.DTOs;

/// <summary>A page of results plus paging metadata.</summary>
public class PagedResult<T>
{
    public List<T> Items { get; set; } = [];
    public int Page { get; set; }
    public int PageSize { get; set; }
    public int Total { get; set; }
    public bool HasMore => Page * PageSize < Total;

    /// <summary>Pages an already-materialized list (for endpoints that must
    /// filter/sort in memory, e.g. nearby-distance lists).</summary>
    public static PagedResult<T> Create(IReadOnlyList<T> source, int page, int pageSize)
    {
        (page, pageSize) = Paging.Clamp(page, pageSize);
        return new PagedResult<T>
        {
            Items = source.Skip((page - 1) * pageSize).Take(pageSize).ToList(),
            Page = page,
            PageSize = pageSize,
            Total = source.Count,
        };
    }
}

/// <summary>Shared paging-parameter sanitization.</summary>
public static class Paging
{
    public const int MaxPageSize = 100;

    public static (int Page, int PageSize) Clamp(int page, int pageSize)
    {
        if (page < 1) page = 1;
        if (pageSize < 1) pageSize = 20;
        if (pageSize > MaxPageSize) pageSize = MaxPageSize;
        return (page, pageSize);
    }
}
