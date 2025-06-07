

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;

entity pop_count is
    generic (N : integer := 8); -- Define bit-width
    port (
        x      : in  std_logic_vector(N-1 downto 0);
        result : out unsigned(integer(ceil(log2(real(N)))) downto 0) -- Enough bits to count up to N
    );
end entity pop_count;

architecture rtl of pop_count is

    constant ACC_SIZE : positive := integer(ceil(log2(real(N)))); -- 8->3, 16->4

begin


    process (x)
        variable accumulator : unsigned(ACC_SIZE downto 0); -- Can count up to 15 (for 8-bit input)
    begin
        accumulator := (others => '0'); -- Initialize to zero
        for ii in 0 to N-1 loop
            if x(ii) = '1' then
                accumulator := accumulator + 1;
            end if;
        end loop;
        result <= accumulator;
    end process;


end rtl;