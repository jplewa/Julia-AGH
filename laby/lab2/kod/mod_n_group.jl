import Base.*
import Base.convert
import Base.promote_rule
import Base.^

# grupa jako całośc jest reprezentowana przez typ Gn{N}, który sam jest obiektem typu Type{Gn{N}}
struct Gn{N} <: Integer
    x :: Int
    function Gn{N}(number) where N          # stworzyć odpowiedni konstruktor sprawdzający warunki utworzenia obiektu danej grupy
        number = mod(number, N)
        if gcd(number, N) == 1 && N > 1     # jeśli reszta nie ma podzielników wspólnych z N poza 1 i N,
            new(number)                     # to należy z niej utworzyć obiekt typu Gn{N}
        else                                # jesli liczba ma wspólne podzielniki należy rzucic wyjątek DomainError
            throw(DomainError())
        end
    end
end

Gn{7}(3)

# Gn{8}(2) -> DomainError()

# taka grupa jest zamknięta ze względu na mnożenie modulo N
function *(a :: Gn{N}, b :: Gn{N}) where N                      # dla obu argumentów typu Gn{N}
    Gn{N}(a.x*b.x)
end

function *(a :: Gn{N}, b :: T) where {N, T <: Integer}    # dla typu Gn{N} i dowolnych pochodnych typu Integer
    Gn{N}(a.x*b)
end

function *(a :: T, b :: Gn{N}) where {N, T <: Integer}    # dla dowolnych pochodnych typu Integer i typu Gn{N}
    Gn{N}(a*b.x)
end

Gn{7}(3) * Gn{7}(6)
Gn{7}(3) * 15
# Gn{8}(1) * 2 -> DomainError()
3 * Gn{10}(1)

# napisać funkcję konwertujacą liczby typu Int64 do typu Gn{N}
# oraz liczby typu Gn{N} do typu Int64
convert( :: Type{Gn{N}}, a :: Int64) where N = gcd(a,N) == 1 && a < N ? Gn{N}(a) : throw(InexactError())
convert( :: Type{Int64}, a :: Gn{N}) where N = a.x

# przetestowac działanie poprzez wymuszenie konwersji
convert(Int64, Gn{7}(5))
convert(Int64, Gn{50}(49))
convert(Gn{7}, 5)
# convert(Gn{8}, 2) -> InexactError()

# napisać regułe promocji dla liczb typu Gn{N} i dowolnego pochodnego typu Integer
promote_rule( :: Type{Gn{N}}, :: Type{T}) where {N, T <: Integer} = T

# sprawdzić czy działa poprzez promote_type
promote_type(Int16, Gn{7})
promote_type(Int64, Gn{100})

# napisac funkcję realizującą działanie a^x mod N dla a typu Gn{N} i x będącą dowolną pochodna typu Integer
function ^(a :: Gn{N}, b :: T) where {N, T <: Integer}
    result = 1
    number = promote(a,b)[1]    # korzystając z poprzedniej funkcji
    for i = 1 : b
        result *= number
        result %= N             # upewnić się, że w trakcie nie są tworzone duże liczby (duże potęgi liczby a)
    end
    Gn{N}(result)
end

Gn{7}(2)^3
Gn{7}(3)^100
Gn{7}(3)^0
Gn{7}(3)^1

# korzystając z poprzedniej funkcji (^) napisać funkcję obliczającą okres danej liczby typu G{N}
# czyli najmniejszą liczbę naturalną r, taką, że a^r mod N =1.
function period(a :: Gn{N}) where N
    o = order(typeof(a))                # można skorzystać z twierdzenia, że r musi dzielić ilość elementów w grupie
    for r = 1 : o
        if o%r == 0 && (a^r).x == 1 return r end
    end
end

# napisac funkcję obliczającą element b odwrotny do a, czyli taki, że (a*b) mod N = 1
function inverse_element(a :: Gn{N}) where N
    extended_gcd(convert(Int64, a), N)          # mozna to zrobić stosując rozszerzony algorytm Euklidesa
end

# rozszerzony algorytm Euklidesa
# zwracający a z równania ax + by = gcd(a,b)
function extended_gcd(a :: T, m :: T) where {T <: Integer}
    m0 = m
    y = 0
    x = 1
    if m == 1
        return 0
    end
    while a > 1
        q = fld(a,m)
        t = m
        m = a % m
        a = t
        t = y
        y = x - q * y
        x = t
    end
    if x < 0
       x += m0
   end
   return x
end

inverse_element(Gn{7}(3))
inverse_element(Gn{7}(5))
inverse_element(Gn{7}(1))
inverse_element(Gn{7}(2))
inverse_element(Gn{7}(4))

# napisać funkcję obliczającą ilość elementów w grupie modulo N
# funkcja powinna przyjmować jako parametr typ Gn{N} (a nie zmienną typu Gn{N})
function order( :: Type{Gn{N}}) where N
    if N < 2 throw(DomainError()) end
    result = 1
    for i = 2 : (N-1)
        if gcd(N, i) == 1
            result += 1
        end
    end
    result
end

order(Gn{7})
order(Gn{101})
# order(Gn{0}) -> DomainError()

period(Gn{7}(1))
period(Gn{7}(2))
period(Gn{7}(3))
period(Gn{7}(4))
period(Gn{7}(5))
period(Gn{7}(6))

# Przetestuj złamanie wiadomości zaszyfrowanej RSA poprzez obliczenie okresu w odpowiedniej grupie
# Mamy dany klucz publiczny składający się z liczb N=55 oraz c=17 oraz zakodowaną wiadomość b=4
N = 55
c = 17
b = 4

r = period(Gn{N}(b))            # oblicz okres r wiadomości b w Gn{N}
d = inverse_element(Gn{r}(c))   # oblicz d - odwrotność do c w Gn{r}. Jest to klucz prywatny
a = Gn{N}(b)^d                  # rozkoduj wiadmość a=b^d mod N

spr = Gn{55}(a)^c               # sprawdz, ze faktycznie ta wiadomość była zakodowana kluczem (N,c) czyli, że b = a^c mod N
println(spr == b)
