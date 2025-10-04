# Type definitions for ArcGISLayers.jl

"""
Abstract base type for all ArcGIS services.
"""
abstract type ArcGISService end

"""
Abstract type for layer-based services (FeatureLayer, Table).
"""
abstract type ArcGISLayer <: ArcGISService end

"""
    QueryParams

Mutable struct for storing query parameters.

# Fields
- `out_fields::Union{Nothing,Vector{String}}`: Fields to return
- `where::Union{Nothing,String}`: SQL where clause
- `return_geometry::Bool`: Whether to return geometry
- `out_sr::Union{Nothing,Int}`: Output spatial reference (EPSG code)
- `geometry_filter::Union{Nothing,Dict{String,Any}}`: Spatial filter parameters
"""
mutable struct QueryParams
    out_fields::Union{Nothing,Vector{String}}
    where::Union{Nothing,String}
    return_geometry::Bool
    out_sr::Union{Nothing,Int}
    geometry_filter::Union{Nothing,Dict{String,Any}}
    
    QueryParams() = new(nothing, nothing, true, nothing, nothing)
end

"""
    FeatureServer

Container service that hosts multiple layers and tables.

# Fields
- `url::String`: Service URL
- `metadata::Dict{String,Any}`: Service metadata from REST API
- `token::Union{Nothing,String}`: Authentication token
"""
struct FeatureServer <: ArcGISService
    url::String
    metadata::Dict{String,Any}
    token::Union{Nothing,String}
end

"""
    MapServer

Service providing map rendering and query capabilities.

# Fields
- `url::String`: Service URL
- `metadata::Dict{String,Any}`: Service metadata from REST API
- `token::Union{Nothing,String}`: Authentication token
"""
struct MapServer <: ArcGISService
    url::String
    metadata::Dict{String,Any}
    token::Union{Nothing,String}
end

"""
    ImageServer

Service providing raster/imagery data.

# Fields
- `url::String`: Service URL
- `metadata::Dict{String,Any}`: Service metadata from REST API
- `token::Union{Nothing,String}`: Authentication token
"""
struct ImageServer <: ArcGISService
    url::String
    metadata::Dict{String,Any}
    token::Union{Nothing,String}
end

"""
    FeatureLayer

Spatial layer containing features with geometry (points, lines, polygons) and attributes.
Queries return DataFrames with a `:geometry` column.

# Fields
- `url::String`: Layer URL
- `metadata::Dict{String,Any}`: Layer metadata from REST API
- `query_params::QueryParams`: Default query parameters
- `token::Union{Nothing,String}`: Authentication token
"""
struct FeatureLayer <: ArcGISLayer
    url::String
    metadata::Dict{String,Any}
    query_params::QueryParams
    token::Union{Nothing,String}
end

"""
    Table

Non-spatial layer containing only tabular/attribute data.
Queries return DataFrames without geometry.

# Fields
- `url::String`: Table URL
- `metadata::Dict{String,Any}`: Table metadata from REST API
- `query_params::QueryParams`: Default query parameters
- `token::Union{Nothing,String}`: Authentication token
"""
struct Table <: ArcGISLayer
    url::String
    metadata::Dict{String,Any}
    query_params::QueryParams
    token::Union{Nothing,String}
end
