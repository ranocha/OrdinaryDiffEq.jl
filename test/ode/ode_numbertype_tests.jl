using OrdinaryDiffEq, DiffEqBase, Base.Test
srand(100)
setprecision(400)

f = (t,u) -> (2u)
analytic = (t,u0) -> u0*exp(t)
prob = ODETestProblem(f,1/2,analytic)


sol3 =solve(prob,RK4(),dt=1/2^(6),abstol=1,reltol=0)

prob = ODETestProblem(f,BigInt(1)//BigInt(2),analytic,(BigInt(0)//BigInt(1),BigInt(1)//BigInt(1)))

integrator = init(prob,RK4(),dt=BigInt(1)//BigInt(2)^(6),abstol=1,reltol=0)

sol =solve(prob,RK4(),dt=BigInt(1)//BigInt(2)^(6),abstol=1,reltol=0)
sol2 =solve(prob,RK4(),dt=BigInt(1)/BigInt(2)^(6),abstol=1,reltol=0)

sol.u
sol2.u
sol3.u
@test eltype(sol.u) == Rational{BigInt}
@test eltype(sol2.u) == Rational{BigInt}
@test eltype(sol3.u) == Float64

sol4 =solve(prob,DP5(),dt=BigInt(1)//BigInt(2)^(3),adaptive=false)

@test eltype(sol4.u) == Rational{BigInt}

tabalg = ExplicitRK(tableau = constructDormandPrince(Rational{BigInt}))

integrator = init(prob,tabalg,dt=BigInt(1)//BigInt(2)^(3),abstol=1,reltol=0,adaptive=false)
sol5 =solve(prob,tabalg,dt=BigInt(1)//BigInt(2)^(3),abstol=1,reltol=0,adaptive=false)

@test typeof(sol5.u[end]) == Rational{BigInt}

prob = ODETestProblem(f,1/2+1/2im,analytic)
