# HTTP client helpers for ArcGISLayers.jl

using HTTP
using JSON

"""
    build_request(url::String, params::Dict{String,Any}=Dict(); 
                  token::Union{Nothing,String}=nothing,
                  method::String="GET") -> HTTP.Request

Build an HTTP request with authentication token support.

# Arguments
- `url::String`: Target URL
- `params::Dict{String,Any}`: Query parameters
- `token::Union{Nothing,String}`: Authentication token
- `method::String`: HTTP method (GET, POST, etc.)

# Returns
HTTP.Request object ready to be executed
"""
function build_request(url::String, params::Dict{String,Any}=Dict(); 
                      token::Union{Nothing,String}=nothing,
                      method::String="GET")
    # Copy params to avoid mutation
    query_params = copy(params)
    
    # Add token if provided
    if token !== nothing
        query_params["token"] = token
    end
    
    # Ensure JSON format if not specified
    if !haskey(query_params, "f")
        query_params["f"] = "json"
    end
    
    return (url=url, params=query_params, method=method)
end

"""
    check_for_errors(response::Dict)

Check an ArcGIS REST API response for errors and throw appropriate exceptions.

# Arguments
- `response::Dict`: Parsed JSON response from ArcGIS REST API

# Throws
- `AuthenticationError`: If authentication is required (codes 498, 499)
- `ArcGISError`: For other ArcGIS API errors
"""
function check_for_errors(response::Dict)
    if haskey(response, "error")
        error_info = response["error"]
        code = get(error_info, "code", nothing)
        message = get(error_info, "message", "Unknown error")
        details = get(error_info, "details", nothing)
        
        # Check for authentication errors
        if code in [498, 499]
            throw(AuthenticationError(
                "Authentication required. Call authenticate(token) first or provide auth parameter."
            ))
        end
        
        throw(ArcGISError(message, code, details))
    end
end

"""
    check_http_status(response::HTTP.Response)

Check HTTP response status code and throw appropriate errors for failures.

# Arguments
- `response::HTTP.Response`: HTTP response object

# Throws
- `AuthenticationError`: For 401 Unauthorized or 403 Forbidden
- `ArcGISError`: For other HTTP error status codes
"""
function check_http_status(response::HTTP.Response)
    status = response.status
    
    # Success codes (2xx)
    if 200 <= status < 300
        return
    end
    
    # Authentication errors
    if status in [401, 403]
        throw(AuthenticationError(
            "Authentication failed (HTTP $status). Verify your token is valid."
        ))
    end
    
    # Client errors (4xx)
    if 400 <= status < 500
        throw(ArcGISError(
            "Client error: HTTP $status",
            status,
            nothing
        ))
    end
    
    # Server errors (5xx)
    if 500 <= status < 600
        throw(ArcGISError(
            "Server error: HTTP $status. The ArcGIS service may be temporarily unavailable.",
            status,
            nothing
        ))
    end
    
    # Other errors
    throw(ArcGISError(
        "Unexpected HTTP status: $status",
        status,
        nothing
    ))
end

"""
    execute_request(url::String, params::Dict{String,Any}=Dict();
                   token::Union{Nothing,String}=nothing,
                   method::String="GET",
                   max_retries::Int=3,
                   retry_delay::Float64=1.0) -> HTTP.Response

Execute an HTTP request with retry logic for transient failures.

# Arguments
- `url::String`: Target URL
- `params::Dict{String,Any}`: Query parameters
- `token::Union{Nothing,String}`: Authentication token
- `method::String`: HTTP method (GET, POST, etc.)
- `max_retries::Int`: Maximum number of retry attempts
- `retry_delay::Float64`: Initial delay between retries in seconds (exponential backoff)

# Returns
HTTP.Response object

# Throws
- `AuthenticationError`: If authentication fails
- `ArcGISError`: For API or HTTP errors after all retries exhausted
"""
function execute_request(url::String, params::Dict{String,Any}=Dict();
                        token::Union{Nothing,String}=nothing,
                        method::String="GET",
                        max_retries::Int=3,
                        retry_delay::Float64=1.0)
    
    # Build request
    req = build_request(url, params; token=token, method=method)
    
    last_error = nothing
    
    for attempt in 1:max_retries
        try
            # Execute request based on method
            response = if uppercase(method) == "GET"
                HTTP.get(req.url; query=req.params)
            elseif uppercase(method) == "POST"
                HTTP.post(req.url; query=req.params)
            else
                error("Unsupported HTTP method: $method")
            end
            
            # Check HTTP status
            check_http_status(response)
            
            return response
            
        catch e
            last_error = e
            
            # Don't retry authentication errors or client errors
            if e isa AuthenticationError
                rethrow(e)
            end
            
            if e isa ArcGISError && e.code !== nothing && 400 <= e.code < 500
                rethrow(e)
            end
            
            # Check if this is a transient error worth retrying
            is_transient = false
            
            if e isa HTTP.StatusError
                # Retry on server errors (5xx) and some client errors
                status = e.status
                is_transient = (500 <= status < 600) || status == 429  # 429 = Too Many Requests
            elseif e isa HTTP.ConnectError || e isa HTTP.TimeoutError
                # Retry on connection and timeout errors
                is_transient = true
            elseif e isa ArcGISError && e.code !== nothing
                # Retry on server errors
                is_transient = 500 <= e.code < 600
            end
            
            # If not transient or last attempt, rethrow
            if !is_transient || attempt == max_retries
                rethrow(e)
            end
            
            # Wait before retry with exponential backoff
            delay = retry_delay * (2 ^ (attempt - 1))
            sleep(delay)
        end
    end
    
    # Should never reach here, but just in case
    throw(last_error)
end

"""
    parse_response(response::HTTP.Response) -> Dict

Parse HTTP response body as JSON and check for errors.

# Arguments
- `response::HTTP.Response`: HTTP response object

# Returns
Parsed JSON response as Dict

# Throws
- `AuthenticationError`: If authentication is required
- `ArcGISError`: For API errors
"""
function parse_response(response::HTTP.Response)
    # Parse JSON
    body = String(response.body)
    result = JSON.parse(body)
    
    # Check for API errors
    check_for_errors(result)
    
    return result
end

"""
    request_json(url::String, params::Dict{String,Any}=Dict();
                token::Union{Nothing,String}=nothing,
                method::String="GET",
                max_retries::Int=3) -> Dict

Execute an HTTP request and return parsed JSON response.

Convenience function that combines execute_request and parse_response.

# Arguments
- `url::String`: Target URL
- `params::Dict{String,Any}`: Query parameters
- `token::Union{Nothing,String}`: Authentication token
- `method::String`: HTTP method (GET, POST, etc.)
- `max_retries::Int`: Maximum number of retry attempts

# Returns
Parsed JSON response as Dict

# Throws
- `AuthenticationError`: If authentication fails
- `ArcGISError`: For API or HTTP errors
"""
function request_json(url::String, params::Dict{String,Any}=Dict();
                     token::Union{Nothing,String}=nothing,
                     method::String="GET",
                     max_retries::Int=3)
    
    response = execute_request(url, params; token=token, method=method, max_retries=max_retries)
    return parse_response(response)
end

