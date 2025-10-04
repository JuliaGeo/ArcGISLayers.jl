# ArcGISLayers.jl - Port Analysis

## Executive Summary

The `arcgislayers` R package provides a comprehensive interface for interacting with ArcGIS REST API services (FeatureServer, MapServer, ImageServer, etc.). It enables reading, writing, querying, and managing vector and raster data from ArcGIS Online, Enterprise, and Location Platform.

## Core Functionality Overview

### 1. **Connection & Discovery** (`arc_open`)
- Opens connections to various ArcGIS services via URL or item ID
- Supports: FeatureServer, FeatureLayer, Table, ImageServer, MapServer, GeocodeServer
- Returns typed objects with metadata about the service
- Handles authentication via tokens

### 2. **Vector Data Reading** (`arc_select`, `arc_read`)
- Query FeatureLayers and Tables with SQL where clauses
- Spatial filtering (intersects, contains, crosses, overlaps, touches, within)
- Field selection and aliasing
- Pagination for large datasets (handles maxRecordCount limits)
- CRS transformation (server-side)
- Returns `sf` objects (spatial) or `data.frame` (tabular)
- Supports Protocol Buffers (PBF) for efficient data transfer when available

### 3. **Raster Data Reading** (`arc_raster`)
- Extract imagery from ImageServers
- Specify bounding box and output dimensions
- Apply raster functions
- CRS transformation
- Returns `terra::SpatRaster` objects

### 4. **Data Writing & Publishing**
- **Create Services** (`create_feature_server`): Create empty FeatureServers
- **Add Features** (`add_features`): Insert new features into layers
- **Update Features** (`update_features`): Modify existing features by ObjectID
- **Delete Features** (`delete_features`): Remove features by ID, where clause, or spatial filter
- **Publish Layers** (`publish_layer`, `publish_item`): Convert R objects to hosted services

### 5. **Attachments** (`query_layer_attachments`, `download_attachments`)
- Query attachment metadata
- Download attachments from features
- Filter by keywords, types, definition expressions

### 6. **Layer Definition Management**
- **Add** (`add_layer_definition`): Add fields, indexes, etc.
- **Update** (`update_layer_definition`): Modify layer properties
- **Delete** (`delete_layer_definition`): Remove definition elements

### 7. **Utility Functions**
- `list_fields()`: Get field metadata
- `list_items()`: List layers/tables in a service
- `refresh_layer()`: Sync with remote changes
- `update_params()`: Modify query parameters
- `truncate_layer()`: Delete all features efficiently
- Field alias and domain value encoding

## Key Technical Patterns

### Authentication
- Token-based authentication via `arc_token()`
- Tokens stored with username and host information
- Passed to all API requests

### Pagination Strategy
1. Count total features with `returnCountOnly=true`
2. Calculate number of pages based on `maxRecordCount`
3. Use `resultOffset` and `resultRecordCount` for pagination
4. Parallel requests with `httr2::req_perform_parallel()`

### CRS Handling
- Validates CRS with `sf::st_crs()`
- Converts to ESRI spatial reference format (WKID)
- Server-side transformation via `outSR` parameter
- Client-side transformation when needed

### Error Handling
- Checks response bodies for error objects
- Provides informative error messages
- Rollback support for write operations

### Data Formats
- **Input**: `sf` objects (spatial), `data.frame` (tabular)
- **Output**: `sf` objects, `data.frame`, `terra::SpatRaster`
- **Wire Format**: GeoJSON, JSON, Protocol Buffers (PBF)

## Architecture Components

### Object Classes
```
FeatureServer (container)
├── FeatureLayer (spatial features)
├── Table (non-spatial records)
└── GroupLayer (nested layers)

ImageServer (raster services)
MapServer (map services)
GeocodeServer (geocoding)
```

### Query Object Pattern
Each layer object has a `query` attribute that stores:
- `outFields`: Field selection
- `where`: SQL filter
- `returnGeometry`: Include/exclude geometry
- `outSR`: Output spatial reference
- Spatial filter parameters

### Request Building
1. Create base request with `arc_base_req(url, token)`
2. Append path (e.g., `/query`, `/addFeatures`)
3. Add form body with parameters
4. Perform request(s)
5. Parse response (JSON or PBF)

## Dependencies & External Libraries

### R Package Dependencies
- **httr2**: HTTP client for REST API calls
- **sf**: Spatial data structures and operations
- **terra**: Raster data handling
- **jsonify**: JSON serialization
- **RcppSimdJson**: Fast JSON parsing
- **arcpbf**: Protocol Buffer parsing
- **arcgisutils**: Shared utilities (CRS validation, geometry conversion)
- **cli**: User-facing messages and progress bars

### Key External Formats
- **Esri JSON**: Geometry and feature representation
- **GeoJSON**: Alternative geometry format
- **Protocol Buffers**: Binary format for efficient transfer
- **TIFF/PNG/JPG**: Raster export formats

## API Endpoints Used

### Query Operations
- `/{service}/query`: Query features
- `/{service}/queryAttachments`: Query attachments

### Write Operations
- `/{service}/addFeatures`: Insert features
- `/{service}/updateFeatures`: Modify features
- `/{service}/deleteFeatures`: Remove features
- `/{service}/truncate`: Delete all features

### Definition Management
- `/{service}/addToDefinition`: Add to layer definition
- `/{service}/updateDefinition`: Modify layer definition
- `/{service}/deleteFromDefinition`: Remove from definition

### Raster Operations
- `/{imageserver}/exportImage`: Export raster data

### Service Management
- `/sharing/rest/content/users/{user}/createService`: Create new service

## Challenges for Julia Port

### 1. **Spatial Data Ecosystem**
- **R**: Mature `sf` package with comprehensive spatial operations
- **Julia**: Need to use GeoInterface.jl ecosystem (ArchGDAL.jl, GeoJSON.jl, etc.)
- **Decision needed**: How to represent spatial features in Julia?

### 2. **Raster Data Handling**
- **R**: `terra` package for raster operations
- **Julia**: Rasters.jl for raster data
- **Question**: How does Rasters.jl handle CRS, bounding boxes, and format conversion?

### 3. **HTTP Client**
- **R**: httr2 with built-in parallel requests
- **Julia**: HTTP.jl (need to implement parallel request pattern)

### 4. **JSON Handling**
- **R**: RcppSimdJson for fast parsing, jsonify for serialization
- **Julia**: JSON3.jl or similar

### 5. **Protocol Buffers**
- **R**: Custom arcpbf package
- **Julia**: ProtoBuf.jl (need to implement Esri PBF format)

### 6. **Progress Bars**
- **R**: cli package
- **Julia**: ProgressMeter.jl

### 7. **Type System**
- **R**: S3 classes with attributes
- **Julia**: Proper type hierarchy with structs

## Recommended Julia Architecture

### Type Hierarchy
```julia
abstract type ArcGISService end
abstract type ArcGISLayer <: ArcGISService end

struct FeatureServer <: ArcGISService
    url::String
    metadata::Dict{String,Any}
    token::Union{Nothing,ArcGISToken}
end

struct FeatureLayer <: ArcGISLayer
    url::String
    metadata::Dict{String,Any}
    query::QueryParams
    token::Union{Nothing,ArcGISToken}
end

struct Table <: ArcGISLayer
    url::String
    metadata::Dict{String,Any}
    query::QueryParams
    token::Union{Nothing,ArcGISToken}
end

struct ImageServer <: ArcGISService
    url::String
    metadata::Dict{String,Any}
    token::Union{Nothing,ArcGISToken}
end

struct QueryParams
    outFields::Union{Nothing,Vector{String}}
    where::Union{Nothing,String}
    returnGeometry::Bool
    outSR::Union{Nothing,Int}
    # ... other query parameters
end
```

### Module Structure
```
ArcGISLayers.jl/
├── src/
│   ├── ArcGISLayers.jl          # Main module
│   ├── types.jl                  # Type definitions
│   ├── auth.jl                   # Authentication
│   ├── connection.jl             # arc_open functionality
│   ├── query.jl                  # arc_select, spatial filters
│   ├── raster.jl                 # arc_raster functionality
│   ├── write.jl                  # add/update/delete features
│   ├── publish.jl                # Publishing services
│   ├── attachments.jl            # Attachment operations
│   ├── definition.jl             # Layer definition management
│   ├── utils.jl                  # Utility functions
│   ├── http.jl                   # HTTP client helpers
│   ├── geometry.jl               # Geometry conversion (Esri JSON <-> GeoInterface)
│   └── pagination.jl             # Pagination logic
```

### Key Design Decisions Needed

1. **Spatial Data Representation**: 
   - Use GeoInterface.jl tables (e.g., GeoDataFrames.jl)?
   - Use ArchGDAL.jl IFeature objects?
   - Custom wrapper type?

2. **Raster Output**:
   - How to construct Rasters.jl Raster objects from downloaded imagery?
   - CRS handling in Rasters.jl?

3. **Async/Parallel Requests**:
   - Use Tasks for parallel pagination?
   - Async HTTP.jl patterns?

4. **Error Handling**:
   - Custom exception types for ArcGIS errors?
   - Error recovery strategies?

5. **Configuration**:
   - Global token storage (like R's `arc_token()`)?
   - Preferences.jl for persistent settings?

## Questions for User

Before proceeding with implementation, I need clarification on:

1. **GeoInterface.jl Usage**: What specific types should be returned for vector data? GeoDataFrames.jl tables? ArchGDAL.jl features? Something else?

2. **Rasters.jl Integration**: 
   - How do I create a Raster from downloaded image bytes?
   - How do I specify CRS, extent, and dimensions?
   - What formats does Rasters.jl support for reading?

3. **Authentication**: Should we use a global token pattern like R, or pass tokens explicitly to each function?

4. **Dependencies**: Are there any Julia packages I should avoid or prefer for HTTP, JSON, or spatial operations?

5. **Naming Conventions**: Should we keep R-style snake_case (arc_select) or use Julia-style camelCase (arcSelect)?

6. **Protocol Buffers**: Is PBF support a priority, or can we start with JSON-only?

## Next Steps

Once the above questions are answered, we can:

1. Create a detailed requirements document
2. Design the type system and API
3. Implement core functionality incrementally:
   - Authentication
   - Connection (arc_open)
   - Basic querying (arc_select)
   - Raster reading (arc_raster)
   - Write operations
   - Advanced features (attachments, definitions, etc.)
