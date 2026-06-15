using AutoMapper;
using SportaApis.DTOs;
using SportaApis.Models;

namespace SportaApis.Helpers;

public class MappingProfile : Profile
{
    public MappingProfile()
    {
        CreateMap<User, UserDto>();
        CreateMap<CreateUserDto, User>();
        CreateMap<UpdateUserDto, User>();
    }
}
