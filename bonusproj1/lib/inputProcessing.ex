defmodule Bonusproj1.CLI do

    @moduledoc """
    This module contains the functionalities of getting command line arguments and then processing the arguments
    """
    
    @doc """
    This function just passes the arguments to parse_args function
    """
    
    def main(args \\ []) do
      args
      |> parse_args
      |> processInput
    end
    
    @doc """
    This function uses the OptionParser.parse function to get the command line arguments
    """
    defp parse_args(args) do
      {_, myArg, _} =
        OptionParser.parse(args,strict: [:integer])
        myArg
    end
  
    @doc """
    This function processes the command line arguments and does appropriate task.
    """
    defp processInput(myArg) do
        cond do
            length(myArg)===0 ->
                IO.puts("Please provide an IP address or the values of n and k")
                System.halt(0)
            length(myArg)===1 ->
                headOfArg=hd(myArg)
                if(headOfArg=~".") do
                    Bonusproj1.Client.startClient(headOfArg)
                else
                    IO.puts("Please provide both n and k")
                    System.halt(0)
                end
            length(myArg)===2 ->
                n=hd(myArg)
                k=tl(myArg)
                Bonusproj1.Server.startServer(n,k)
        end
    end
end
