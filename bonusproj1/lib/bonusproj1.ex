defmodule Bonusproj1.Server do
  
  @moduledoc """
  A module which implements all the functionalities of the Server.
  """
  

  
  
  @doc """
  A method which starts the server node by extracting the IP address using :inet.getif() function.
  A check is also performed to see if the node is connected to the internet or not

  IMPORTANT INSTRUCTIONS REGARDING :inet.getif/0 function

  PART ONE: (NO VMWARE OR VIRTUAL BOX IS INSTALLED)
  
  1. FOR WINDOWS 7 AND OLDER VERSIONS OF WINDOWS 10,THE IPADDRESS IS AT POSITION 1 OF THE TUPLE(0 based indexing).
  2. FOR NEWER VERSIONS OF WINDOWS 10 THE IPADDRESS IS AT POSITION 0(i.e first element of tuple) OF THE TUPLE(0 BASED INDEXING).
  3. FOR UBUNTU BASED OS THE IPADDRESS IS AT POSITION 0(i.e first element of tuple) OF THE TUPLE(0 BASED INDEXING).
  
  PART TWO: (VMWARE OR VIRTUAL BOX IS INSTALLED)

  1. VMWARE/VIRTUALBOX CREATES ADAPTERS SO NEW IP ADDRESSES WILL BE CREATED.
  2. SO BEFORE RUNNING THE PROJECT, RUN THE :inet.getif/0 function AND USE THE APPROPRIATE INDEX BY CHANGING THE INDEX IN THE enum.at/2 function.
  """
  
  def startServer(n,k) do
    IO.puts("Starting Server ...")
    {:ok,ipAddressList}=:inet.getif()
    if(length(ipAddressList)==1) do
      IO.puts("The Machine is offline")
      System.halt(0);
    else
      osTuple=:os.type
      osType=Atom.to_string(elem(osTuple,0))
      if(osType=~"win") do
        {ipAddressTuple,_BroadcastAddress,_mask}=Enum.at(ipAddressList,0)
        nodeSetup(ipAddressTuple,n,k)
      else
        {ipAddressTuple,_BroadcastAddress,_mask}=Enum.at(ipAddressList,0)
        nodeSetup(ipAddressTuple,n,k)
      end
    end
  end

  @doc """
  A function which starts the server node, sets the cookie and registers the server pid on the network. 
  """
  
  def nodeSetup(ipAddressTuple,n,k) do
    IO.puts("Setting up the Server Node...")
    ipAddress=Integer.to_string(elem(ipAddressTuple,0))<>"."<>Integer.to_string(elem(ipAddressTuple,1))<>"."<>Integer.to_string(elem(ipAddressTuple,2))<>"."<>Integer.to_string(elem(ipAddressTuple,3))
    nodeName = "Elixir@"<>ipAddress
    Node.start(String.to_atom(nodeName))
    Node.set_cookie(String.to_atom(nodeName),:dos)
    :global.register_name(:serverPID,self())
    sendMessageToClient(n,k)

  end

  @doc """
  A function which checks if there are any clients on the network.
  First the server registers itself as client for the work of computation.
  Then it waits for another node.
  Here only the code has been run on 2 machines.
  """
  
  def sendMessageToClient(n,k) do
    IO.puts("Checking for Client PID List")
    clientPIDList=[]
    clientPIDList=Enum.concat(clientPIDList,[self()])
    
    if(length(Node.list)===2) do
      IO.inspect(clientPIDList)
      distributeTask(clientPIDList,n,k)
    else
      storeClientPID(clientPIDList,n,k)
    end
    
  end

  @doc """
  A function which stores the Process IDs of client in a List
  """
  
  def storeClientPID(clientPIDList,n,k) do
    
    if(length(clientPIDList)==2) do
      distributeTask(clientPIDList,n,k)
    else
      receive do
        {:ready,clientPID} -> 
          clientPIDList=Enum.concat(clientPIDList,[clientPID])
          storeClientPID(clientPIDList,n,k)
        end
    end
    
    
  end

  @doc """
  A function which distributes the value of n among 2 machines.
  
  """
  def distributeTask(clientPIDList,n,k) do
    IO.inspect("Distributing the task among clients")
    serverpid=:global.whereis_name(:serverPID)
    totalWorkLoad=String.to_integer(n)
    myK=String.to_integer(hd(k))
    noOfMachines=length(clientPIDList)
    workLoadForClient=Float.floor((totalWorkLoad/noOfMachines),0)
    for i <- 1..noOfMachines do
      currentClientPID=Enum.at(clientPIDList,i-1)
      send currentClientPID,{:task,(i-1)*workLoadForClient+1,i*workLoadForClient,myK}
      IO.inspect(send currentClientPID,{:task,(i-1)*workLoadForClient+1,i*workLoadForClient,myK})
    end
    getWorkFromServer(serverpid)
    getOutput(0)
  end

  @doc """
  A function which gets the work (i.e StartLimit and EndLimit for k) from server.

  """
  
  def getWorkFromServer(serverpid) do
    IO.puts("Getting Work")
    receive do
      {:task,startPoint,endPoint,k} -> calAnswer(serverpid,startPoint,endPoint,k)
    end
  end

  @doc """
  A function which distributes the task among actors of the given node.
  """
  
  def calAnswer(serverpid,startPoint,endPoint,k) do
    
    totalWorkload=endPoint-startPoint+1
    totalActors=10
    workUnit=Float.ceil(totalWorkload/totalActors)
    Enum.each(
      1..totalActors,
      fn(x)->
        actor=spawn(__MODULE__,:startWorker,[self()])
        
        startLimit=((x-1)*workUnit)+startPoint
        if(x===totalActors) do
          endLimit=endPoint
          send actor,{startLimit,endLimit,totalWorkload,k}
          IO.inspect(send actor,{startLimit,endLimit,totalWorkload,k})
        else
          endLimit=(x*workUnit)
          send actor,{startLimit,endLimit,totalWorkload,k}
          IO.inspect(send actor,{startLimit,endLimit,totalWorkload,k})
        end 
        
      end
      )
      getActorMessage(0,totalActors,[],serverpid)
  end
  
  
  
  @doc """
    A function which receives messages from actors.
    Two types of messages are received.
    1. When a perfect sqaure is found.
    2. When the actor has finished it's task.

  """  
  
  def getActorMessage(myCount,totalActors,myList,serverpid) do
    receive do
              
          {:found, startIndexFinal} ->
          myList=Enum.concat(myList,[Kernel.trunc(startIndexFinal)]) 
          getActorMessage(myCount,totalActors,myList,serverpid)
              
          {:ActorComplete,_startIndexFinal} ->
          theCount=myCount+1
          getActorMessage(theCount,totalActors,myList,serverpid)

          {:NodeComplete,_aaa} ->
            outputToServer(myList,serverpid)
    end
  end


  @doc """
  A function which sends the list of Start Indexes to the server.

  """
  
  def outputToServer(myList,serverpid) do
    IO.puts("Output from Server and Client to Server")
    myList=Enum.uniq(myList)
    Enum.each(myList,fn(x) -> send serverpid,{:getIndexFromServer,x}
                                   end)  
    send serverpid,{:byeBye,-1}
  end

  @doc """
    A function where each actor receives it's task from the Boss.
    
  """
  
  def startWorker(boss_pid) do
    
    receive do
      
      {firstIndex,lastIndex,n,k} ->
                                  checkPerfectSquare(boss_pid,firstIndex,lastIndex,n,k)    
    end
  end


  @doc """
    A function which calculates the sum of sqaures of consecutive numbers.

  """
    
  def consecutiveSquareSum(boss_pid,res,k,num) do
    if num == k do
      res+num*num
    else
      new_res = res + num*num
      consecutiveSquareSum(boss_pid,new_res,k,num-1)
    end
  end


  @doc """
    A function which checks if a number is a perfect square or not.
    If the number is a perfect square, a message is sent to Boss.
    Also we notify the boss when we are done with the task of checking perfect square.
  """
   
  def checkPerfectSquare(boss_pid,firstIndex,lastIndex,n,k) do
    
    if firstIndex>n do
     
      send boss_pid,{:NodeComplete,-1}
    else
      if(firstIndex>lastIndex) do
       

        send boss_pid,{:ActorComplete,-1}

      else
        abc=consecutiveSquareSum(boss_pid,0,firstIndex,firstIndex+k-1)
        getSq=:math.sqrt(abc)
        getSqString=Float.to_string(getSq)
        splitSq=String.split(getSqString,".")
        decimalPart=List.last(splitSq)
        
        if decimalPart==="0" do
          send boss_pid,{:found,firstIndex}
          IO.inspect(send boss_pid,{:found,firstIndex})
          checkPerfectSquare(boss_pid,firstIndex+1,lastIndex,n,k)
        else
          checkPerfectSquare(boss_pid,firstIndex+1,lastIndex,n,k)
        end
      end
    end
  end

  @doc """
  A function which prints the output on the console when it receives it's message from server and client
  """
  
  def getOutput(myCount) do
    
    if(myCount===2) do
      IO.puts("End of Output")
    else
      receive do
        {:getIndexFromServer, startIndexFinal} ->
        IO.inspect(Kernel.trunc(startIndexFinal)) 
        getOutput(myCount)
              
        {:getIndexFromClient, startIndexFinal} ->
        IO.inspect(Kernel.trunc(startIndexFinal))
        getOutput(myCount)

        {:byeBye,_startIndexFinal} ->
        theCount=myCount+1
        getOutput(theCount)  
      end
    end
  end
end
