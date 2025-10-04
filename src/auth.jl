# Authentication management for ArcGISLayers.jl

"""
Global token storage for ArcGIS authentication.
Use `authenticate(token)` to set the global token.
"""
const GLOBAL_TOKEN = Ref{Union{Nothing,String}}(nothing)

"""
    authenticate(token::String)

Set the global authentication token for ArcGIS API requests.

# Arguments
- `token::String`: Your ArcGIS authentication token

# Examples
```julia
authenticate("your_token_here")
```

# Requirements
Satisfies requirements 1.1, 1.2
"""
function authenticate(token::String)
    GLOBAL_TOKEN[] = token
    return nothing
end

"""
    authenticate()

Interactive authentication flow that prompts for a token.

# Examples
```julia
authenticate()
# Enter your ArcGIS token: [user enters token]
```

# Requirements
Satisfies requirements 1.2, 1.3
"""
function authenticate()
    println("Enter your ArcGIS token:")
    token = readline()
    authenticate(token)
    println("Authentication token set successfully.")
    return nothing
end

"""
    get_token(auth::Union{Nothing,String})

Helper function to retrieve the authentication token for API requests.
Returns the provided auth parameter if not nothing, otherwise returns the global token.

# Arguments
- `auth::Union{Nothing,String}`: Optional authentication token override

# Returns
- `Union{Nothing,String}`: The authentication token to use, or nothing if no token is set

# Examples
```julia
# Use global token
token = get_token(nothing)

# Use specific token
token = get_token("specific_token")
```

# Requirements
Satisfies requirements 1.3, 1.4, 1.5
"""
function get_token(auth::Union{Nothing,String})
    if auth !== nothing
        return auth
    end
    return GLOBAL_TOKEN[]
end
