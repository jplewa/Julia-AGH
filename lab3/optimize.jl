# bez optymalizacji
# 20.764874 seconds (123.16 M allocations: 6.596 GiB, 12.54% gc time)

# po ustawieniu N i K jako stałych
# 4.143603 seconds (5.66 M allocations: 3.799 GiB, 10.56% gc time)

# po zmianie dostępu do tablic na column-major
# 4.008481 seconds (5.59 M allocations: 3.799 GiB, 12.70% gc time)

# po dodaniu typów pól w strukturach oraz zamianie globalnego graph na argument funkcji
# 3.993192 seconds (5.60 M allocations: 3.797 GiB, 10.11% gc time)

# po zamianie tablicy A z Int64 na BitArray
# 3.985283 seconds (4.02 M allocations: 3.264 GiB, 12.35% gc time)

# po sparametryzowaniu nodes (Vector{NodeType})
# 3.374032 seconds (2.87 M allocations: 3.247 GiB, 16.13% gc time)

# po wykorzystaniu funkcji map w convert_to_graph (zamiast tworzenia pustej tablicy i sukcesywnego wypełniania jej)
# 3.743985 seconds (2.76 M allocations: 3.244 GiB, 12.78% gc time)

# po rozbiciu graph_to_str na kilka funkcji i skorzystaniu z IOBuffer
# 1.633283 seconds (2.00 M allocations: 139.938 MiB, 2.22% gc time)

# Kod maszynowy zoptymalizowanego programu jest dłuższy niż niezoptymalizowanna wersja, ponieważ obsługuje bardziej konkretne przypadki.
# Przy pomocy makra @code_warntype można zaobserwować, że w zoptymalizowanym programie nie występują niepewne zmienne ani kolekcje typu Any.


module Graphs

using StatsBase

export GraphVertex, NodeType, Person, Address,
       generate_random_graph, get_random_person, get_random_address, generate_random_nodes,
       convert_to_graph,
       bfs, check_euler, partition,
       graph_to_str, node_to_str,
       test_graph

# Types of valid graph node's values.
abstract type NodeType end

#= Single graph vertex type.
Holds node value and information about adjacent vertices =#
mutable struct GraphVertex{T <: NodeType}
  value :: T
  neighbors :: Vector{GraphVertex}
end

mutable struct Person <: NodeType
  name :: String
end

mutable struct Address <: NodeType
  streetNumber :: Int8
end

# Number of graph nodes.
const N = Int64(800)

# Number of graph edges.
const K = Int64(10000)

#= Generates random directed graph of size N with K edges
and returns its adjacency matrix.=#
function generate_random_graph()
  A :: BitArray{2} = falses(N, N)
  for i in sample(1:N*N, K, replace = false)
    A[i] = true
  end
  A
end

# Generates random person object (with random name).
function get_random_person()
  Person(randstring()) :: NodeType
end

# Generates random person object (with random name).
function get_random_address()
  Address(rand(1:100)) :: NodeType
end

# Generates N random nodes (of random NodeType).
function random_node()
  rand() > 0.5 ? get_random_person() : get_random_address()
end

function generate_random_nodes()
  nodes = Vector{NodeType}()
  for i = 1:N
    push!(nodes, random_node())
  end
  nodes
end

#= Converts given adjacency matrix (NxN)
  into list of graph vertices (of type GraphVertex and length N). =#
function create_vertex(person :: Person)
  GraphVertex{Person}(person, Vector{GraphVertex}())
end

function create_vertex(address :: Address)
  GraphVertex{Address}(address, Vector{GraphVertex}())
end

function convert_to_graph(A :: BitArray{2}, nodes :: Vector{NodeType})
  graph :: Array{GraphVertex,1} = map(n -> create_vertex(n), nodes)

  for i = 1:N
    for j = 1:N
       if A[j,i]
         push!(graph[i].neighbors, graph[j])
      end
    end
  end
  graph
end

#= Groups graph nodes into connected parts. E.g. if entire graph is connected,
  result list will contain only one part with all nodes. =#
function partition(graph::Array{GraphVertex,1})
  parts = Set{GraphVertex}[]
  remaining = Set(graph)
  visited = bfs(graph, remaining = remaining)
  push!(parts, Set(visited))

  while !isempty(remaining)
    new_visited = bfs(graph, visited = visited, remaining = remaining)
    push!(parts, new_visited)
  end
  parts
end

#= Performs BFS traversal on the graph and returns list of visited nodes.
  Optionally, BFS can initialized with set of skipped and remaining nodes.
  Start nodes is taken from the set of remaining elements. =#
function bfs(graph :: Array{GraphVertex,1}; visited :: Set{GraphVertex}=Set{GraphVertex}(), remaining :: Set{GraphVertex}=Set(graph))
  first = next(remaining, start(remaining))[1]
  q :: Array{GraphVertex,1} = [first]
  push!(visited, first)
  delete!(remaining, first)
  local_visited :: Set{GraphVertex} = Set([first])

  while !isempty(q)
    v = pop!(q)
    for n in v.neighbors
      if !(n in visited)
        push!(q, n)
        push!(visited, n)
        push!(local_visited, n)
        delete!(remaining, n)
      end
    end
  end
  local_visited
end

#= Checks if there's Euler cycle in the graph by investigating
   connectivity condition and evaluating if every vertex has even degree =#
function check_euler(graph::Array{GraphVertex,1})
  if length(partition(graph)) == 1
    return all(map(v -> iseven(length(v.neighbors)), graph))
  end
    "Graph is not connected"
end

#= Returns text representation of the graph consisiting of each node's value
   text and number of its neighbors. =#
function node_to_str(buffer :: IOBuffer, n :: Person )
   print(buffer, "****\nPerson: ", n.name)
 end

function node_to_str(buffer :: IOBuffer, n :: Address)
  print(buffer, "****\nStreet nr: ", n.streetNumber)
end

function vertex_to_buffer(buffer :: IOBuffer, v :: GraphVertex)
  node_to_str(buffer, v.value)
  print(buffer, "\nNeighbors: ", length(v.neighbors), "\n")
end

function graph_to_str(graph::Array{GraphVertex,1})
  #graph_str = ""
  buffer = IOBuffer()
  for v in graph
    vertex_to_buffer(buffer, v)
  end
  String(take!(buffer))
end

#= Tests graph functions by creating 100 graphs, checking Euler cycle
  and creating text representation. =#
function test_graph()
  for i = 1:100
    A = generate_random_graph()
    nodes = generate_random_nodes()
    graph = convert_to_graph(A, nodes)
    str = graph_to_str(graph)
    # println(str)
    println(check_euler(graph))
  end
end

end

@time Graphs.test_graph()
