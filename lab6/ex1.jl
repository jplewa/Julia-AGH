# x is the number that will be printed out by the task
# n describes how many times each number (1-3) will be printed
function f(x, n)
    global counter
    while counter < 3*n
        if (counter % 3 + 1) == x
            print(x, " ")
            counter+=1
        end
        yield()
    end
end

function test_tasks(n)
    global counter = 0
    for i in shuffle(1:3)
        @async f(i,n)
    end
end

@sync test_tasks(10)
println()

# result: 1 2 3 1 2 3 1 2 3 1 2 3 1 2 3 1 2 3 1 2 3 1 2 3 1 2 3 1 2 3
