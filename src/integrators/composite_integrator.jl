#=

Maybe do generated functions to reduce dispatch times?

f(x) = x
g(x,i) = f(x[i])
g{i}(x,::Type{Val{i}}) = f(x[i])
@generated function gg(tup::Tuple, num)
                  N = length(tup.parameters)
                  :(@nif $(N+1) i->(i == num) i->(f(tup[i])) i->error("unreachable"))
              end
h(i) = g((1,1.0,"foo"), i)
h2{i}(::Type{Val{i}}) = g((1,1.0,"foo"), Val{i})
h3(i) = gg((1,1.0,"foo"), i)
@benchmark h(1)
mean time:        31.822 ns (0.00% GC)
@benchmark h2(Val{1})
mean time:        1.585 ns (0.00% GC)
@benchmark h3(1)
mean time:        6.423 ns (0.00% GC)

@generated function foo(tup::Tuple, num)
  N = length(tup.parameters)
  :(@nif $(N+1) i->(i == num) i->(tup[i]) i->error("unreachable"))
end

@code_typed foo((1,1.0), 1)

@generated function perform_step!(integrator,cache::CompositeCache,f=integrator.f)
  N = length(cache.parameters)
  :(@nif $(N+1) i->(i == num) i->(tup[i]) i->error("unreachable"))
end

=#

@inline function initialize!(integrator,cache::CompositeCache,f=integrator.f)
  cache.current = cache.choice_function(integrator)
  initialize!(integrator,cache.caches[cache.current])
  resize!(integrator.k,integrator.kshortsize)
end

@inline function perform_step!(integrator,cache::CompositeCache,f=integrator.f)
  perform_step!(integrator,cache.caches[cache.current],f)
end

@inline choose_algorithm!(integrator,cache::OrdinaryDiffEqCache) = nothing
@inline function choose_algorithm!(integrator,cache::CompositeCache)
  new_current = cache.choice_function(integrator)
  if new_current != cache.current
    initialize!(integrator,cache.caches[new_current])
    reset_alg_dependent_opts!(integrator,integrator.alg.algs[cache.current],integrator.alg.algs[new_current])
    transfer_cache!(integrator,integrator.cache.caches[cache.current],integrator.cache.caches[new_current])
    cache.current = new_current
  end
end

"""
If no user default, then this will change the default to the defaults
for the second algorithm.
"""
@inline function reset_alg_dependent_opts!(integrator,alg1,alg2)
  integrator.dtchangeable = isdtchangeable(alg2)
  if integrator.opts.adaptive == isadaptive(alg1)
    integrator.opts.adaptive = isadaptive(alg2)
  end
  if integrator.opts.qmin == qmin_default(alg1)
    integrator.opts.qmin = qmin_default(alg2)
  end
  if integrator.opts.qmax == qmax_default(alg1)
    integrator.opts.qmax == qmax_default(alg2)
  end
  if integrator.opts.beta2 == beta2_default(alg1)
    integrator.opts.beta2 = beta2_default(alg2)
  end
  if integrator.opts.beta1 == beta1_default(alg1,integrator.opts.beta2)
    integrator.opts.beta1 = beta1_default(alg2,integrator.opts.beta2)
  end
end

# Write how to transfer the cache variables from one cache to the other
# Example: send the history variables from one multistep method to another

@inline transfer_cache!(integrator,alg1,alg2) = nothing
