# Error types and handling for ArcGISLayers.jl

"""
    ArcGISError <: Exception

General error from ArcGIS REST API.

# Fields
- `message::String`: Error message
- `code::Union{Nothing,Int}`: HTTP or ArcGIS error code
- `details::Union{Nothing,Dict}`: Additional error details
"""
struct ArcGISError <: Exception
    message::String
    code::Union{Nothing,Int}
    details::Union{Nothing,Dict}
end

ArcGISError(message::String) = ArcGISError(message, nothing, nothing)
ArcGISError(message::String, code::Int) = ArcGISError(message, code, nothing)

"""
    AuthenticationError <: Exception

Error indicating authentication is required or has failed.

# Fields
- `message::String`: Error message
"""
struct AuthenticationError <: Exception
    message::String
end

"""
    InvalidCRSError <: Exception

Error indicating an invalid or unsupported coordinate reference system.

# Fields
- `crs::Any`: The invalid CRS value
- `message::String`: Error message
"""
struct InvalidCRSError{T} <: Exception
    crs::T
    message::String
end

"""
    UnsupportedGeometryError <: Exception

Error indicating an unsupported geometry type.

# Fields
- `message::String`: Error message
"""
struct UnsupportedGeometryError <: Exception
    message::String
end

"""
    QueryError <: Exception

Error during query execution.

# Fields
- `message::String`: Error message
- `query::Dict`: Query parameters that caused the error
"""
struct QueryError{D <: AbstractDict} <: Exception
    message::String
    query::D
end

QueryError(message::String) = QueryError(message, Dict())

# Custom error message formatting
Base.showerror(io::IO, e::ArcGISError) = begin
    print(io, "ArcGISError: ", e.message)
    if e.code !== nothing
        print(io, " (code: ", e.code, ")")
    end
    if e.details !== nothing
        print(io, "\nDetails: ", e.details)
    end
end

Base.showerror(io::IO, e::AuthenticationError) = 
    print(io, "AuthenticationError: ", e.message)

Base.showerror(io::IO, e::InvalidCRSError) = 
    print(io, "InvalidCRSError: ", e.message, " (CRS: ", e.crs, ")")

Base.showerror(io::IO, e::UnsupportedGeometryError) = 
    print(io, "UnsupportedGeometryError: ", e.message)

Base.showerror(io::IO, e::QueryError) = begin
    print(io, "QueryError: ", e.message)
    if !isempty(e.query)
        print(io, "\nQuery parameters: ", e.query)
    end
end
