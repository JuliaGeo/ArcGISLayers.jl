using ArcGISLayers
using Test
using HTTP
using JSON

@testset "ArcGISLayers.jl" begin
    @testset "Connection (arc_open)" begin
        # Test with a public ArcGIS Online service
        # Using ESRI's sample server
        
        @testset "Open service from URL" begin
            # This is a public sample service from ESRI
            url = "https://sampleserver6.arcgisonline.com/arcgis/rest/services/USA/MapServer/0"
            
            try
                service = arc_open(url)
                @test service isa ArcGISService
                @test service.url == url
                @test haskey(service.metadata, "name") || haskey(service.metadata, "type")
            catch e
                # If the service is unavailable, skip the test
                if e isa ArcGISError || e isa HTTP.Exceptions.ConnectError
                    @warn "Skipping test: Sample server unavailable"
                else
                    rethrow(e)
                end
            end
        end
        
        @testset "Invalid URL handling" begin
            # Test with an invalid URL
            invalid_url = "https://invalid.arcgis.com/invalid/service"
            
            @test_throws Exception arc_open(invalid_url)
        end
        
        @testset "Service type determination" begin
            # Test determine_service_type function
            
            # FeatureLayer with geometry
            @test ArcGISLayers.determine_service_type(
                "https://example.com/FeatureServer/0",
                Dict("geometryType" => "esriGeometryPoint")
            ) == :FeatureLayer
            
            # Table without geometry
            @test ArcGISLayers.determine_service_type(
                "https://example.com/FeatureServer/0",
                Dict("type" => "Table")
            ) == :Table
            
            # FeatureServer
            @test ArcGISLayers.determine_service_type(
                "https://example.com/FeatureServer",
                Dict()
            ) == :FeatureServer
            
            # ImageServer
            @test ArcGISLayers.determine_service_type(
                "https://example.com/ImageServer",
                Dict()
            ) == :ImageServer
            
            # MapServer
            @test ArcGISLayers.determine_service_type(
                "https://example.com/MapServer/0",
                Dict()
            ) == :MapServer
        end
        
        @testset "Service object construction" begin
            # Test construct_service_object function
            url = "https://example.com/FeatureServer/0"
            metadata = Dict("name" => "Test Layer")
            token = nothing
            
            # FeatureLayer
            obj = ArcGISLayers.construct_service_object(:FeatureLayer, url, metadata, token)
            @test obj isa FeatureLayer
            @test obj.url == url
            @test obj.metadata == metadata
            
            # Table
            obj = ArcGISLayers.construct_service_object(:Table, url, metadata, token)
            @test obj isa Table
            
            # FeatureServer
            obj = ArcGISLayers.construct_service_object(:FeatureServer, url, metadata, token)
            @test obj isa FeatureServer
            
            # ImageServer
            obj = ArcGISLayers.construct_service_object(:ImageServer, url, metadata, token)
            @test obj isa ImageServer
            
            # MapServer
            obj = ArcGISLayers.construct_service_object(:MapServer, url, metadata, token)
            @test obj isa MapServer
            
            # Unknown type
            @test_throws ArcGISError ArcGISLayers.construct_service_object(:Unknown, url, metadata, token)
        end
    end
end
