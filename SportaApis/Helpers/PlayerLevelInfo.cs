using SportaApis.Enums;

namespace SportaApis.Helpers;

/// <summary>
/// Maps a self-assessment score to the 7-level player scale and exposes
/// localized names for each level.
/// </summary>
public static class PlayerLevelInfo
{
    private static readonly Dictionary<PlayerLevel, (string Ar, string En)> _names = new()
    {
        [PlayerLevel.Beginner] = ("مبتدئ", "Beginner"),
        [PlayerLevel.Novice] = ("ناشئ", "Novice"),
        [PlayerLevel.Learner] = ("متعلم", "Learner"),
        [PlayerLevel.Intermediate] = ("متوسط", "Intermediate"),
        [PlayerLevel.Advanced] = ("متقدم", "Advanced"),
        [PlayerLevel.Professional] = ("محترف", "Professional"),
        [PlayerLevel.Elite] = ("نخبة", "Elite"),
    };

    public static string NameAr(PlayerLevel level) => _names[level].Ar;
    public static string NameEn(PlayerLevel level) => _names[level].En;

    /// <summary>
    /// Computes a level from a list of per-question scores (each 0..3).
    /// The ratio of the achieved score over the maximum maps onto levels 1..7.
    /// </summary>
    public static PlayerLevel FromAnswers(IReadOnlyList<int> answers)
    {
        if (answers.Count == 0) return PlayerLevel.Beginner;

        var clamped = answers.Select(a => Math.Clamp(a, 0, 3)).ToList();
        var max = clamped.Count * 3.0;
        var ratio = clamped.Sum() / max; // 0.0 .. 1.0

        // 0 → Beginner (1), 1 → Elite (7)
        var level = (int)Math.Round(ratio * 6) + 1;
        return (PlayerLevel)Math.Clamp(level, 1, 7);
    }
}
