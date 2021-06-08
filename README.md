# Curry

A simple module to do currying and partial application using Variadic functionsto start partial evaluation (i.e. no lists needed).

See: 
  Currying:
 
    iex(9)> curry_fun = curry(&Curry.test3/3)
    #Function<0.51120925/1 in Curry.curry/1>

    iex(10)> next_fun = curry_fun.(1)
    #Function<1.51120925/1 in Curry.do_generate_next/3>

    iex(11)> next_fun = next_fun.(77)
    #Function<1.51120925/1 in Curry.do_generate_next/3>

    iex(12)> next_fun_or_result = next_fun.(10)
    {88, {1, 77, 10}}

    iex(13> info(curry_fun)
    [
      function: &Curry.test3/3,
      type: "Currying",
      function_arity: 3,
      args_still_needed: 3,
      args_collected: 0
    ]

  Partial application:

    iex(20)> partial_fun = partial(&Curry.test5/5, 1, 2)
    #Function<19.126501267/3 in :erl_eval.expr/5>

    iex(21)> info(partial_fun)
    [
      function: &Curry.test5/5,
      type: "Partial application",
      function_arity: 5,
      args_still_needed: 3,
      args_collected: 2
    ]

    iex(22)> partial_fun.(3, 4, 5)
    {15, {1, 2, 3, 4, 5}}
