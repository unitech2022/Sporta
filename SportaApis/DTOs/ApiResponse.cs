namespace SportaApis.DTOs;

public class ApiResponse<T>
{
    public bool Success { get; set; }
    public T? Data { get; set; }
    public string? Message { get; set; }
    public string? MessageAr { get; set; }
    public string? Code { get; set; }

    public static ApiResponse<T> Ok(T data) =>
        new() { Success = true, Data = data };

    public static ApiResponse<T> Fail(string message, string? messageAr = null, string? code = null) =>
        new() { Success = false, Message = message, MessageAr = messageAr, Code = code };
}
