defmodule Worker do
    @moduledoc """
    A module that performs all the functions of a Worker in a Boss Worker model.
    
    """


    @doc """
    A function where each actor receives it's task from the Boss.
    
    """
    def startWorker(boss_pid) do
        receive do
            {firstIndex,lastIndex,k} -> checkPerfectSquare(boss_pid,firstIndex,lastIndex,k)
         end
    end

    @doc """
    A function which calculates the sum of sqaures of consecutive numbers.

    """
    
    def consecutiveSquareSum(res,k,num) do
        if num == k do
            res+num*num
        else
            new_res = res + num*num
            consecutiveSquareSum(new_res,k,num-1)
        end
   end

   @doc """
   A function which checks if a number is a perfect square or not.
   If the number is a perfect square, a message is sent to Boss.
   Also we notify the boss when we are done with the task of checking perfect square.
   """
   
   def checkPerfectSquare(boss_pid,firstIndex,lastIndex,k) do 
        if firstIndex>lastIndex do
            send boss_pid,{:complete,-1}
        else

            abc=consecutiveSquareSum(0,firstIndex,firstIndex+k-1)
            getSq=:math.sqrt(abc)
            getSqString=Float.to_string(getSq)
            splitSq=String.split(getSqString,".")
            decimalPart=List.last(splitSq)
            
            if decimalPart==="0" do
                send boss_pid,{:found,firstIndex}
                checkPerfectSquare(boss_pid,firstIndex+1,lastIndex,k)
            else
                checkPerfectSquare(boss_pid,firstIndex+1,lastIndex,k)
            end
        end
    end
end



defmodule Boss do

    @moduledoc """
    A module which implements the functionalities of Boss in a Boss Worker Model.
    """
    
    @doc """
    A function which receives messages from actors.
    Two types of messages are received.
    1. When a perfect sqaure is found.
    2. When the actor has finished it's task.

    """
    
    def getActorMessage(myCount,totalActors) do
        if(myCount===totalActors) do
            IO.puts("End of Output")
        else
            receive do
                    
                {:found, startIndexFinal} ->
                IO.inspect(Kernel.trunc(startIndexFinal)) 
                getActorMessage(myCount,totalActors)
                    
                {:complete,_startIndexFinal} ->
                theCount=myCount+1
                getActorMessage(theCount,totalActors)
                
            end
        end
    end
    
    @doc """
    A function which gets the number of actors.
    
    """    
    def getNumActors(n) do
        if(n<10) do
            n
        else
            10
        end
    end

    @doc """
    A function which distributes the task among actors.

    """
    def calAnswer(n,k) do
        totalActors=getNumActors(n)
        totalWorkLoad=n
        workUnit=Float.ceil(totalWorkLoad/totalActors)
        Enum.each(
            1..totalActors,
            fn(x)->
                actor=spawn(Worker,:startWorker,[self()])
                startLimit=((x-1)*workUnit)+1
                if(x===totalActors) do
                    endLimit=totalWorkLoad
                    send actor,{startLimit,endLimit,k}
                else
                    endLimit=x*workUnit
                    send actor,{startLimit,endLimit,k}    
		        end
            end
        ) 
        getActorMessage(0,totalActors)   
    end
end