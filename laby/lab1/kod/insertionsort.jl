function insSort(arr)
    for i = 2:length(arr)
        key = arr[i]
        j = i-1
        while j >= 1 && arr[j] > key
            arr[j+1] = arr[j]
            j -= 1
        end
        arr[j+1] = key
    end
end

a = []
println(a)
insSort(a)
println(a)
