
-- temp1 : Ch(E,F,G) + H + W + K --[]--> ch_pip
-- temp2 : E1(E)_d + ch_pip --[]--> sigma1_pip
-- temp3 : Maj(A,B,C)_dd + sigma1_pip --[]--> maj_pip
-- temp4 : maj_pip + E0(A)_ddd --> A
-- D_dd + sigma1_pip ----> E

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.pkg_fun.all;


entity iteration is
    port (
        clk     : in std_logic;
        reset   : in std_logic;
        H_input : in std_logic_vector(1 to 256);
        W_input : in std_logic_vector(1 to 32);
        K_input : in std_logic_vector(1 to 32);
        H_output: out std_logic_vector(1 to 256)
    );
end entity iteration;

architecture rtl of iteration is

    alias A_in : std_logic_vector(1 to 32) is H_input(1 to 32);
    alias B_in : std_logic_vector(1 to 32) is H_input(33 to 64);
    alias C_in : std_logic_vector(1 to 32) is H_input(65 to 96);
    alias D_in : std_logic_vector(1 to 32) is H_input(97 to 128);
    alias E_in : std_logic_vector(1 to 32) is H_input(129 to 160);
    alias F_in : std_logic_vector(1 to 32) is H_input(161 to 192);
    alias G_in : std_logic_vector(1 to 32) is H_input(193 to 224);
    alias H_in : std_logic_vector(1 to 32) is H_input(225 to 256);    
    ------------------------------------------------------------------
    alias A_out : std_logic_vector(1 to 32) is H_output(1 to 32);
    alias B_out : std_logic_vector(1 to 32) is H_output(33 to 64);
    alias C_out : std_logic_vector(1 to 32) is H_output(65 to 96);
    alias D_out : std_logic_vector(1 to 32) is H_output(97 to 128);
    alias E_out : std_logic_vector(1 to 32) is H_output(129 to 160);
    alias F_out : std_logic_vector(1 to 32) is H_output(161 to 192);
    alias G_out : std_logic_vector(1 to 32) is H_output(193 to 224);
    alias H_out : std_logic_vector(1 to 32) is H_output(225 to 256);    
    --
    signal ch : unsigned(1 to 32);
    signal ch_pip : unsigned(1 to 32);
    signal sigma1 : unsigned(1 to 32);
    signal sigma1_d : unsigned(1 to 32);
    signal maj : unsigned(1 to 32);
    signal sigma0 : unsigned(1 to 32);
    signal temp1 : unsigned(1 to 32);
    signal temp2 : unsigned(1 to 32);
    signal temp3 : unsigned(1 to 32);
    signal temp1_d : unsigned(1 to 32);
    signal temp2_d : unsigned(1 to 32);
    signal temp3_d : unsigned(1 to 32);

    -- temp
    signal only_A : std_logic_vector(1 to 32);
    signal only_E : std_logic_vector(1 to 32);
    

begin

    -- CH
    process (all)
    begin
        ch <= unsigned((E_in and F_in) xor ((not E_in) and G_in));
    end process;

    -- temp1
    process (all)
    begin
        temp1 <= ch + unsigned(H_in) + unsigned(W_input) + unsigned(K_input);
    end process;

    process (clk, reset)
    begin
        if reset = '1' then
            temp1_d <= (others => '0');
        elsif rising_edge(clk) then
            temp1_d <= temp1;
        end if;
    end process;

    -- SIGMA1
    process (all)
    begin
        sigma1 <= unsigned(sigma_1(E_in));
    end process;

    process (clk, reset)
    begin
        if reset = '1' then
            sigma1_d <= (others => '0');
        elsif rising_edge(clk) then
            sigma1_d <= sigma1;
        end if;
    end process;


    process (all)
    begin
        temp2 <= sigma1_d + temp1_d;
    end process;

    process (clk, reset)
    begin
        if reset = '1' then
            temp2_d <= (others => '0');
        elsif rising_edge(clk) then
            temp2_d <= temp2;
        end if;
    end process;


    -- MAJ
    process (all)
    begin
        maj <= unsigned((A_in and B_in) xor (A_in and C_in) xor (B_in and C_in));
    end process;


    process (all)
    begin
        temp3 <= maj + temp2_d;
    end process;

    process (clk, reset)
    begin
        if reset = '1' then
            temp3_d <= (others => '0');
        elsif rising_edge(clk) then
            temp3_d <= temp3;
        end if;
    end process;

    -- SIGMA0
    process (all)
    begin
        sigma0 <= unsigned(sigma_0(A_in));
    end process;


    -- OUT
    A_out <= std_logic_vector(sigma0 + temp3_d);
    only_A <= A_out;
    B_out <= A_in;
    C_out <= B_in;
    D_out <= C_in;
    E_out <= std_logic_vector(unsigned(D_in) + temp2_d);
    only_E <= E_out;
    F_out <= E_in;
    G_out <= F_in;
    H_out <= G_in;
    

end architecture;