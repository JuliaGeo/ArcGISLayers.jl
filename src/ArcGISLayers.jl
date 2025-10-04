module ArcGISLayers

# Import dependencies
using HTTP
using JSON
using DataFrames
using Tables
using GeoInterface
using Rasters
using ArchGDAL
using ProgressMeter
using ProtoBuf

# Include submodules
include("errors.jl")
include("types.jl")
include("auth.jl")
include("http.jl")
include("connection.jl")
include("utils.jl")
include("geometry.jl")
include("spatial_filter.jl")
include("query.jl")
include("pagination.jl")
include("response_parser.jl")
include("raster.jl")
include("write.jl")
include("publish.jl")
include("definition.jl")
include("attachments.jl")

# Export types
export ArcGISService, ArcGISLayer
export FeatureServer, MapServer, ImageServer
export FeatureLayer, Table
export QueryParams

# Export error types
export ArcGISError, AuthenticationError, InvalidCRSError
export UnsupportedGeometryError, QueryError

# Export main functions
export authenticate
# export arc_open
# export arc_select
# export arc_raster
# export add_features, update_features, delete_features
# export create_feature_server
# export list_fields, list_items, refresh_layer, get_layer_estimates
# export query_layer_attachments, download_attachments
# export add_layer_definition, update_layer_definition, delete_layer_definition
# export truncate_layer

end
