using LinearAlgebra, SparseArrays, Test

using MultivariatePolynomials
using SumOfSquares

# Taken from JuMP/test/solvers.jl
function try_import(name::Symbol)
    try
        @eval import $name
        return true
    catch e
        return false
    end
end

if try_import(:DynamicPolynomials)
    import DynamicPolynomials.@polyvar
    import DynamicPolynomials.@ncpolyvar
else
    if try_import(:TypedPolynomials)
        import TypedPolynomials.@polyvar
    else
        error("No polynomial implementation installed : Please install TypedPolynomials or DynamicPolynomials")
    end
end

include("certificate.jl")

include("gram_matrix.jl")

include("variable.jl")
include("constraint.jl")

include("Mock/mock_tests.jl")

# Tests needed a solver
# FIXME these tests should be moved to `Tests` and tested in `Mock`
include("solvers.jl")
include("sospoly.jl")
include("lyapunov.jl")
include("sosdemo3.jl")
include("domain.jl")
include("sosquartic.jl")
include("equalitypolyconstr.jl")
include("extract.jl")
