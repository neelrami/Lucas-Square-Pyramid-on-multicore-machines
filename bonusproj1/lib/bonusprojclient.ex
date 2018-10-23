defmodule Bonusproj1.Client do

  @moduledoc """
  A module which implements all the functionalities of the Client.
  """  

  @doc """
  A method which starts the client node by extracting the IP address using :inet.getif() function.
  A check is also performed to see if the node is connected to the internet or not

  IMPORTANT INSTRUCTIONS REGARDING :inet.getif/0 function

  PART ONE: (NO VMWARE OR VIRTUAL BOX IS INSTALLED)
  
  1. FOR WINDOWS 7 AND OLDER VERSIONS OF WINDOWS 10, THE IPADDRESS IS AT POSITION 1 OF THE TUPLE(0 based indexing).
  2. FOR NEWER VERSIONS OF WINDOWS 10 THE IPADDRESS IS AT POSITION 0(i.e first element of tuple) OF THE TUPLE(0 BASED INDEXING).
  3. FOR UBUNTU BASED OS THE IPADDRESS IS AT POSITION 0(i.e first element of tuple) OF THE TUPLE(0 BASED INDEXING).
  
  PART TWO: (VMWARE OR VIRTUAL BOX IS INSTALLED)

  1. VMWARE/VIRTUALBOX CREATES ADAPTERS SO NEW IP ADDRESSES WILL BE CREATED.
  2. SO BEFORE RUNNING THE PROJECT, RUN THE :inet.getif/0 function AND USE THE APPROPRIATE INDEX BY CHANGING THE INDEX IN THE enum.at/2 function.
  """
  
  def startClient(serverIP) do
    IO.puts("Starting Client")
    {:ok,ipAddressList}=:inet.getif()
    if(length(ipAddressList)==1) do
      IO.puts("The Machine is offline")
      System.halt(0);
    else
      osTuple=:os.type
      osType=Atom.to_string(elem(osTuple,0))
      if(osType=~"win") do
        {ipAddressTuple,_BroadcastAddress,_mask}=Enum.at(ipAddressList,0)
        nodeSetup(ipAddressTuple,serverIP)
      else
        {ipAddressTuple,_BroadcastAddress,_mask}=Enum.at(ipAddressList,0)
        nodeSetup(ipAddressTuple,serverIP)
      end
    end
  end
  
  @doc """
  A function which starts the server node, sets the cookie and registers the server pid on the network. 
  """
  
  def nodeSetup(ipAddressTuple,serverIP) do
    IO.puts("Node Setup")
    ipAddress=Integer.to_string(elem(ipAddressTuple,0))<>"."<>Integer.to_string(elem(ipAddressTuple,1))<>"."<>Integer.to_string(elem(ipAddressTuple,2))<>"."<>Integer.to_string(elem(ipAddressTuple,3))
    nodeName = "Elixir@"<>ipAddress
    Node.start(String.to_atom(nodeName))
    Node.set_cookie(String.to_atom(nodeName),:dos)
    serverNode = "Elixir@"<>serverIP
    serverNodeName=String.to_atom(serverNode)
    Node.connect(serverNodeName)
    checkforServerPID()
  end
  

  @doc """
  A function which checks for the availiablity of the server pid on the network. 
  """
  
  def checkforServerPID() do
    :global.sync()
    IO.puts("Checking for Server PID")
    if(:global.whereis_name(:serverPID)==:undefined) do
      checkforServerPID()
    else
      serverpid=:global.whereis_name(:serverPID)
      send serverpid, {:ready,self() }
      getWorkFromServer(serverpid)
    end
  end

  @doc """
  A function which gets the work (i.e StartLimit and EndLimit for k) from server. 
  """
  
  def getWorkFromServer(serverpid) do
    IO.puts("Getting Work from Server")
    receive do
      {:task,startPoint,endPoint,k} -> calAnswer(serverpid,startPoint, endPoint,k)
    end
  end
  
  @doc """
  A function which distributes the task among actors of the given node.
  """

  def calAnswer(serverpid,startPoint, endPoint,k) do
    IO.puts("Calculating Answer")
    totalWorkload=endPoint - startPoint + 1
    totalActors=10
    workUnit=Float.ceil(totalWorkload/totalActors)
    Enum.each(
      1..totalActors,
      fn(x)->
        actor=spawn(__MODULE__,:startWorker,[self()])
        
        startLimit=((x-1)*workUnit)+startPoint
		
        if(x===totalActors) do
          endLimit=endPoint
          send actor,{startLimit,endLimit,totalWorkload,k,endPoint}
		      IO.inspect(send actor,{startLimit,endLimit,totalWorkload,k,endPoint})
          
        else
          endLimit=(x*workUnit)+startPoint-1
          send actor,{startLimit,endLimit,totalWorkload,k,endPoint}
          IO.inspect(send actor,{startLimit,endLimit,totalWorkload,k,endPoint})

          
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
    IO.puts("Sending Output to Server")
    myList=Enum.uniq(myList)
    Enum.each(myList,fn(x) -> send serverpid,{:getIndexFromClient,x} end)
	  IO.inspect(length(myList)) 
    send serverpid,{:byeBye,-1}
  end

  @doc """
    A function where each actor receives it's task from the Boss.
    
  """

  def startWorker(boss_pid) do
    
    receive do
      
      {firstIndex,lastIndex,n,k,endPoint} ->
                                  checkPerfectSquare(boss_pid,firstIndex,lastIndex,n,k,endPoint)
                                  
    IO.inspect(checkPerfectSquare(boss_pid,firstIndex,lastIndex,n,k,endPoint))
      
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
  
  def checkPerfectSquare(boss_pid,firstIndex,lastIndex,n,k,endPoint) do
	
    if firstIndex>endPoint do
     
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
          checkPerfectSquare(boss_pid,firstIndex+1,lastIndex,n,k,endPoint)
		
		
        else
          checkPerfectSquare(boss_pid,firstIndex+1,lastIndex,n,k,endPoint)
		
        end
      end
    end
  end
end