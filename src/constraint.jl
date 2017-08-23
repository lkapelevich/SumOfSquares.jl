export SOSCone, getslack, addpolyconstraint!

struct SOSCone end
const NonNegPolySubCones = Union{NonNegPoly, SOSCone}

struct SOSConstraint{MT <: AbstractMonomial, MVT <: AbstractVector{MT}}
    slack::MatPolynomial{JuMP.Variable, MT, MVT}
    lincons::Vector{JuMP.ConstraintRef{JuMP.Model,JuMP.GenericRangeConstraint{JuMP.GenericAffExpr{Float64,JuMP.Variable}}}}
    x::MVT
end

function JuMP.getdual(c::SOSConstraint)
    a = [getdual(lc) for lc in c.lincons]
    Measure(a, c.x)
end

function addpolyconstraint!(m::JuMP.Model, p, s::ZeroPoly, domain::FullSpace)
    constraints = [JuMP.constructconstraint!(AffExpr(t.α), :(==)) for t in p]
    JuMP.addVectorizedConstraint(m, constraints)
end

function addpolyconstraint!(m::JuMP.Model, p, s::ZeroPoly, domain::AlgebraicSet)
    if !isempty(domain.p)
        warn("Equality on algebraic set has not been implemented yet, ignoring the domain")
    end
    addpolyconstraint!(m, p, FullSpace())
end

function addpolyconstraint!(m::JuMP.Model, p, s::ZeroPoly, domain::BasicSemialgebraicSet)
    addpolyconstraint!(m,  p, NonNegPoly(), domain)
    addpolyconstraint!(m, -p, NonNegPoly(), domain)
    nothing
end

function addpolyconstraint!(m::JuMP.Model, P::Matrix{PT}, ::PSDCone, domain::AbstractBasicSemialgebraicSet) where PT <: APL
    n = Base.LinAlg.checksquare(P)
    if !issymmetric(P)
        throw(ArgumentError("The polynomial matrix constrained to be SOS must be symmetric"))
    end
    y = [similarvariable(PT, gensym()) for i in 1:n]
    p = dot(y, P * y)
    addpolyconstraint!(m, p, NonNegPoly(), domain)
end

function addpolyconstraint!(m::JuMP.Model, p, ::Union{NonNegPoly, SOSCone}, domain::FullSpace)
    # FIXME If p is a MatPolynomial, p.x will not be correct
    Z = getmonomialsforcertificate(monomials(p))
    slack = createpoly(m, Poly{true}(Z), :Cont)
    q = p - slack
    lincons = addpolyconstraint!(m, q, ZeroPoly(), domain)
    SOSConstraint(slack, lincons, monomials(q))
end

function addpolyconstraint!(m::JuMP.Model, p, s::NonNegPolySubCones, domain::AlgebraicSet)
    if !isempty(equalities(domain))
        warn("Equality on algebraic set has not been implemented yet, ignoring the domain")
    end
    addpolyconstraint!(m, p, s, FullSpace())
end

function addpolyconstraint!(m::JuMP.Model, p, set::NonNegPolySubCones, domain::BasicSemialgebraicSet)
    mindeg, maxdeg = extdegree(p)
    for q in domain.p
        mindegq, maxdegq = extdegree(q)
        mind = mindeg - mindegq
        maxd = maxdeg - maxdegq
        mind = max(0, Int(floor(mind / 2)))
        maxd = Int(ceil(maxd / 2))
        # FIXME handle the case where `p`, `q_i`, ...  do not have the same variables
        # so instead of `variable(p)` we would have the union of them all
        @assert variables(q) ⊆ variables(p)
        s = createpoly(m, Poly{true}(monomials(variables(p), mind:maxd)), :Cont)
        p -= s*q
    end
    addpolyconstraint!(m, p, set, domain.V)
end
