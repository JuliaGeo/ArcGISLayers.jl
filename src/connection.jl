# Service connection and discovery for ArcGISLayers.jl

"""
    fetch_service_metadata(url::String, token::Union{Nothing,String}) -> AbstractDict

Fetch metadata from an ArcGIS service endpoint.

# Arguments
- `url::String`: Service URL
- `token::Union{Nothing,String}`: Authentication token

# Returns
Dictionary containing service metadata from the REST API

# Throws
- `AuthenticationError`: If authentication is required but not provided
- `ArcGISError`: For API or HTTP errors

# Requirements
Satisfies requirements 2.6, 2.7, 2.8
"""
function fetch_service_metadata(url::String, token::Union{Nothing,String})
    # Use the request_json helper from http.jl
    metadata = request_json(url, Dict{String,Any}(); token=token)
    return metadata
end

"""
    determine_service_type(url::String, metadata::AbstractDict) -> Symbol

Determine the type of ArcGIS service from URL and metadata.

# Arguments
- `url::String`: Service URL
- `metadata::AbstractDict`: Service metadata from REST API

# Returns
Symbol representing the service type: `:FeatureServer`, `:FeatureLayer`, 
`:Table`, `:ImageServer`, or `:MapServer`

# Throws
- `ArcGISError`: If service type cannot be determined

# Requirements
Satisfies requirements 2.1, 2.2, 2.3, 2.4, 2.5
"""
function determine_service_type(url::String, metadata::AbstractDict)
    # Check URL path for service type indicators
    
    # FeatureLayer or Table (layer within a FeatureServer)
    if occursin(r"/FeatureServer/\d+$", url)
        # Check if it has geometry - FeatureLayer has geometryType, Table does not
        if haskey(metadata, "geometryType") && metadata["geometryType"] !== nothing
            return :FeatureLayer
        else
            return :Table
        end
    end
    
    # FeatureServer (container service)
    if occursin(r"/FeatureServer/?$", url)
        return :FeatureServer
    end
    
    # ImageServer
    if occursin(r"/ImageServer/?$", url)
        return :ImageServer
    end
    
    # MapServer
    if occursin(r"/MapServer", url)
        return :MapServer
    end
    
    # If we can't determine from URL, try metadata
    if haskey(metadata, "type")
        service_type = metadata["type"]
        if service_type == "Feature Layer"
            return :FeatureLayer
        elseif service_type == "Table"
            return :Table
        end
    end
    
    # Unable to determine service type
    throw(ArcGISError(
        "Unable to determine service type from URL: $url. " *
        "Ensure the URL points to a valid ArcGIS REST service.",
        nothing,
        nothing
    ))
end

"""
    construct_service_object(service_type::Symbol, url::String, 
                            metadata::AbstractDict, token::Union{Nothing,String}) -> ArcGISService

Construct the appropriate service object based on service type.

# Arguments
- `service_type::Symbol`: Type of service (`:FeatureServer`, `:FeatureLayer`, etc.)
- `url::String`: Service URL
- `metadata::AbstractDict`: Service metadata
- `token::Union{Nothing,String}`: Authentication token

# Returns
Appropriate service object (FeatureServer, FeatureLayer, Table, ImageServer, or MapServer)

# Throws
- `ArcGISError`: If service type is unknown

# Requirements
Satisfies requirements 2.1, 2.2, 2.3, 2.4, 2.5, 2.8
"""
function construct_service_object(service_type::Symbol, url::String, 
                                 metadata::AbstractDict, token::Union{Nothing,String})
    if service_type == :FeatureServer
        return FeatureServer(url, metadata, token)
    elseif service_type == :FeatureLayer
        return FeatureLayer(url, metadata, QueryParams(), token)
    elseif service_type == :Table
        return Table(url, metadata, QueryParams(), token)
    elseif service_type == :ImageServer
        return ImageServer(url, metadata, token)
    elseif service_type == :MapServer
        return MapServer(url, metadata, token)
    else
        throw(ArcGISError(
            "Unknown service type: $service_type",
            nothing,
            nothing
        ))
    end
end

"""
    arc_open(url::String; auth=nothing) -> ArcGISService

Open a connection to an ArcGIS service and return the appropriate service type.

This is the main entry point for connecting to ArcGIS REST services. It automatically
detects the service type (FeatureServer, FeatureLayer, Table, ImageServer, or MapServer)
and returns the appropriate typed object with metadata.

# Arguments
- `url::String`: URL to the ArcGIS REST service endpoint
- `auth::Union{Nothing,String}`: Authentication token (optional, defaults to global token)

# Returns
One of: `FeatureServer`, `FeatureLayer`, `Table`, `ImageServer`, or `MapServer`

# Throws
- `AuthenticationError`: If authentication is required but not provided
- `ArcGISError`: For invalid URLs, unreachable services, or API errors

# Examples
```julia
# Open a public FeatureLayer
layer = arc_open("https://services.arcgisonline.com/arcgis/rest/services/World/FeatureServer/0")

# Open with authentication
authenticate("your_token_here")
layer = arc_open("https://services.arcgis.com/.../FeatureServer/0")

# Or provide token directly
layer = arc_open(url, auth="your_token_here")

# Open a FeatureServer (container)
server = arc_open("https://services.arcgisonline.com/arcgis/rest/services/World/FeatureServer")

# Open an ImageServer
img_server = arc_open("https://services.arcgisonline.com/arcgis/rest/services/World/ImageServer")
```

# Requirements
Satisfies requirements 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8
"""
function arc_open(url::String; auth=nothing)
    # Get authentication token (from parameter or global)
    token = get_token(auth)
    
    # Fetch metadata from service
    # This will throw AuthenticationError if auth is required but not provided
    metadata = fetch_service_metadata(url, token)
    
    # Determine service type from URL and metadata
    service_type = determine_service_type(url, metadata)
    
    # Construct and return appropriate service object
    return construct_service_object(service_type, url, metadata, token)
end
