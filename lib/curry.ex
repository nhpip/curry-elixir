#
# MIT License
#
# Copyright (c) 2021 Matthew Evans
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

defmodule Curry do
  @moduledoc """

  ====================================================================================

  A simple module to do currying and partial application using Variadic functions
  to start partial evaluation (i.e. no lists needed).

  ## Currying example:

      iex> curry_fun = curry(&Curry.test3/3)
      #Function<0.51120925/1 in Curry.curry/1>

      iex> next_fun = curry_fun.(1)
      #Function<1.51120925/1 in Curry.do_generate_next/3>

      iex> next_fun = next_fun.(77)
      #Function<1.51120925/1 in Curry.do_generate_next/3>

      iex)> next_fun_or_result = next_fun.(10)
      {88, {1, 77, 10}}

      iex> info(curry_fun)
      [
        function: &Curry.test3/3,
        type: "Currying",
        function_arity: 3,
        args_still_needed: 3,
        args_collected: 0
      ]

  ## Partial application example:

      iex> partial_fun = partial(&Curry.test5/5, 1, 2)
      #Function<19.126501267/3 in :erl_eval.expr/5>

      iex> info(partial_fun)
      [
        function: &Curry.test5/5,
        type: "Partial application",
        function_arity: 5,
        args_still_needed: 3,
        args_collected: 2
      ]

      iex> partial_fun.(3, 4, 5)
      {15, {1, 2, 3, 4, 5}}

    ====================================================================================

  """

  import Variadic

  @doc """
  Does currying of the supplied function (capture)

  ## Example:

      iex> curry_fun = curry(&Curry.test3/3)
      #Function<0.82106290/1 in Curry.curry/1>
      iex> curry_fun.(1).(2).(3)
      {6, {1, 2, 3}}

  ## Example:

      iex> curry_fun = Curry.~>(&Curry.test3/3)
      #Function<0.82106290/1 in Curry.curry/1>
      iex> last = curry_fun.(1).(2)
      #Function<1.82106290/1 in Curry.do_generate_next/3>
      iex> last.(3)
      {6, {1, 2, 3}}
  """
  def curry(fun), do:
    fn arg -> do_generate_next(fun, [arg], :curry) end

  def unquote(:~>)(fun), do: curry(fun)

  @doc """
  Does partial application

  ## Example:

      iex> partial_fun = Curry.partial(&Curry.test5/5, 1, 2)
      #Function<19.126501267/3 in :erl_eval.expr/5>
      iex> partial_fun.(3, 4, 5)
      {15, {1, 2, 3, 4, 5}}

  ## Example:

      iex> partial_fun = Curry.~>>(&Curry.test5/5, 1, 2)
      #Function<19.126501267/3 in :erl_eval.expr/5>
      iex> partial_fun.(3, 4, 5)
      {15, {1, 2, 3, 4, 5}}
  """
  def partial(args)
  @doc false
  defv :partial do
    [fun|arguments] = args_to_list(binding())
    do_generate_next(fun, arguments, :partial)
  end

  defv :~>> do
    [fun|arguments] = args_to_list(binding())
    do_generate_next(fun, arguments, :partial)
  end

  def do_generate_next(fun, args, type) do
    {_, arity} = :erlang.fun_info(fun, :arity)

    case arity - length(args) do
      0 ->
        Kernel.apply(fun, args)

      val when val > 0 and type == :curry ->
        ## We are currying, return a function that takes a single argument
        fn arg -> do_generate_next(fun, args ++ [arg], type) end

      1 ->
        ## We are doing partial application and need 1 more argument
        fn arg1 -> do_generate_next(fun, args ++ [arg1], type) end

      2 ->
        ## We are doing partial application and need 2 more arguments
        fn arg1, arg2 -> do_generate_next(fun, args ++ [arg1, arg2], type) end

      arity when arity > 0 ->
        ## Still doing partial application, so we don't get a crazy long case statement
        ## we can actually make our own function. A bit slower to make than doing directly, but still pretty fast
        make_lambda(arity, fun, args, type)

      _ ->
        raise(%RuntimeError{message: "Bad arity. Should be #{arity} but got #{length(args)}"})
    end
  end

  @doc """
  Gets information on your lambda

  ## Example:

      iex> Curry.info(partial_fun)
      [
        function: &Curry.test5/5,
        type: "Partial application",
        function_arity: 5,
        args_still_needed: 3,
        args_collected: 2
      ]
  """
  def info(fun) do
    {_, env} = :erlang.fun_info(fun, :env)
    {_, module} = :erlang.fun_info(fun, :module)

    {tfun, args, type} = case module do
      Curry ->
        [f|a] = env
        t = Enum.find(a, fn e -> is_atom(e) end)
        a = List.flatten(a) |> Enum.filter(fn e -> not is_atom(e) end)
        {f, a, t}

      _ ->
        [{plist, _, _, _}] = env
        [{_,a}|_] = Enum.filter(plist, fn {_,e} -> is_list(e) end)
        [{_,f}|_] = Enum.filter(plist, fn {_,e} -> is_function(e) end)
        [{_,t}|_] = Enum.filter(plist, fn {_,e} -> is_atom(e) end)
        {f, a, t}
    end

    type = if type == :partial do "Partial application" else "Currying" end

    {_, arity} = :erlang.fun_info(tfun, :arity)
    args_collected = length(List.flatten(args))

    [
      function: tfun,
      type: type,
      function_arity: arity,
      args_still_needed: arity - args_collected,
      args_collected: args_collected
    ]
  end

  ##
  ## Some test functions
  ##
  def test0(), do: :hello

  def test1(a), do: {a * 5, a}

  def test2(a, b), do: {a + b, {a, b}}

  def test3(a, b, c), do: {a + b + c, {a, b, c}}

  def test4(a, b, c, d), do: {a + b + c + d, {a, b, c, d}}

  def test5(a, b, c, d, e), do: {a + b + c + d + e, {a, b, c, d, e}}

  defp make_lambda(arity, fun, args, type) do
    arg_list = for arg <- 1..arity do
      last_arg = if arg != arity do ", " else "" end
      "arg" <> to_string(arg) <> last_arg
    end

    arg_list = List.to_string(arg_list)
    fun_cmd = "fn(" <> arg_list <> ") -> Curry.do_generate_next(fun, args ++ [" <> arg_list <> "], type) end"

    {_, tokens} = :elixir.string_to_tokens(String.to_charlist(fun_cmd), 1, "", [])
    {_, forms} = :elixir.tokens_to_quoted(tokens, "", [])
    bindings = :erl_eval.add_binding('B', 2, [fun: fun, args: args, type: type])

    {lambda,_,_} = :elixir.eval_forms(forms,bindings,[])
    lambda
  end

end
