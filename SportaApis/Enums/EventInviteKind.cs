namespace SportaApis.Enums;

/// <summary>ما يُدعى إليه الصديق.</summary>
public enum EventInviteKind
{
    Match = 0,      // مباراة — TargetId = Match.Id
    Americano = 1,  // أمريكانو — TargetId = AmericanoMatch.Id
    Tournament = 2, // بطولة — TargetId = AmericanoMatch.Id
}

public enum EventInviteStatus
{
    Pending = 0,
    Accepted = 1, // انضم المدعو فعلاً إلى الحدث
    Declined = 2,
}
