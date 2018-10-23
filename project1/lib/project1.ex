defmodule Project1.CLI do
    def main(args \\ []) do
      args
      |> parse_args
      |> processInput
    end
  
    defp parse_args(args) do
      {_, myArg, _} =
        OptionParser.parse(args,strict: [:integer])
        myArg
    end
  
    defp processInput(myArg) do
        cond do
            length(myArg)===0 ->
                IO.puts("Please provide the values of n and k")
                System.halt(0)
            length(myArg)===1 ->
                IO.puts("Please provide both n and k")
                System.halt(0)
            length(myArg)===2 ->
                n=hd(myArg)
                k=tl(myArg)
                newN=String.to_integer(n)
		        newK=String.to_integer(hd(k))
                Boss.calAnswer(newN,newK)
                
        end
    end
end
