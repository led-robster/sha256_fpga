

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.pkg_fun.all;


entity block_processor is
    port (
        clk         : in std_logic;
        reset       : in std_logic;
        start       : in std_logic;
        H_i         : in std_logic_vector(1 to 256);
        block_i     : in std_logic_vector(1 to 512);
        ready       : out std_logic;
        block_o     : out std_logic_vector(1 to 256)
    );
end entity block_processor;

architecture rtl of block_processor is

    type shift_register is array (1 to 16) of std_logic_vector(1 to 32);
    signal W_arr : shift_register;
    signal K_arr : matrix;

    signal K_input : std_logic_vector(1 to 32);
    signal W_input : std_logic_vector(1 to 32);
    signal H_input : std_logic_vector(1 to 256);
    signal H_output : std_logic_vector(1 to 256);
    signal H_output_stable : std_logic_vector(1 to 256);
    signal H_initial : std_logic_vector(1 to 256);

    alias X_0 : std_logic_vector(1 to 32) is block_i(1 to 32);
    alias X_1 : std_logic_vector(1 to 32) is block_i(33 to 64);
    alias X_2 : std_logic_vector(1 to 32) is block_i(65 to 96);
    alias X_3 : std_logic_vector(1 to 32) is block_i(97 to 128);
    alias X_4 : std_logic_vector(1 to 32) is block_i(129 to 160);
    alias X_5 : std_logic_vector(1 to 32) is block_i(161 to 192);
    alias X_6 : std_logic_vector(1 to 32) is block_i(193 to 224);
    alias X_7 : std_logic_vector(1 to 32) is block_i(225 to 256);
    alias X_8 : std_logic_vector(1 to 32) is block_i(257 to 288);
    alias X_9 : std_logic_vector(1 to 32) is block_i(289 to 320);
    alias X_10 : std_logic_vector(1 to 32) is block_i(321 to 352);
    alias X_11 : std_logic_vector(1 to 32) is block_i(353 to 384);
    alias X_12 : std_logic_vector(1 to 32) is block_i(385 to 416);
    alias X_13 : std_logic_vector(1 to 32) is block_i(417 to 448);
    alias X_14 : std_logic_vector(1 to 32) is block_i(449 to 480);
    alias X_15 : std_logic_vector(1 to 32) is block_i(481 to 512);


    signal A_out : std_logic_vector(1 to 32);
    signal B_out : std_logic_vector(1 to 32);
    signal C_out : std_logic_vector(1 to 32);
    signal D_out : std_logic_vector(1 to 32);
    signal E_out : std_logic_vector(1 to 32);
    signal F_out : std_logic_vector(1 to 32);
    signal G_out : std_logic_vector(1 to 32);
    signal H_out : std_logic_vector(1 to 32);


    signal boot : std_logic;

    signal block_end : std_logic;

    signal cnt_cc : unsigned(1 downto 0);
    signal cnt_en : std_logic;

    signal stop_cnt : unsigned(7 downto 0);


begin

    iter_unit : entity work.iteration
     port map(
        clk => clk,
        reset => reset,
        H_input => H_input,
        W_input => W_input,
        K_input => K_input,
        H_output => H_output
    );


    -- stop generation
    process (clk, reset)
    begin
        if reset = '1' then
            block_end <= '0';
            ready <= '0';
        elsif rising_edge(clk) then

            ready <= '0';
            
            if K_arr(1)=x"00000000" then
                if cnt_cc="11" then
                    ready <= '1';
                    block_end <= '1';
                end if;
            end if;


            if start='1' then
                block_end <= '0';
            end if;
                    
        end if;
    end process;

    -- K_gen
    process (clk, reset)
    begin
        if reset = '1' then
            K_arr <= K_TABLE;
        elsif rising_edge(clk) then

            if (boot='1') then
                K_arr <= K_TABLE;
                K_input <= K_arr(1);
                if cnt_cc="11" then
                    K_arr(1 to 64) <= K_arr(2 to 64) & x"00000000"; 
                end if;
            end if;

            if (cnt_cc="11") then
                K_input <= K_arr(1);
                K_arr(1 to 64) <= K_arr(2 to 64) & x"00000000"; 
            end if;

        end if;
    end process;

    -- W_gen
    process (clk, reset)
    begin
        if reset = '1' then

            W_arr <= (others => (others => '0')); -- ???

        elsif rising_edge(clk) then
            
            if (boot='1') then
                W_arr <= (1 => X_0, 2 => X_1, 3=>X_2, 4=>X_3, 5=>X_4, 6=>X_5, 7=>X_6, 8=>X_7, 9=>X_8, 10=>X_9, 11=>X_10, 12=>X_11, 13=>X_12, 14=>X_13, 15=>X_14, 16=>X_15);
            end if;

            if (cnt_cc="11") then
                W_input <= W_arr(1);
                W_arr(1 to 15) <= W_arr(2 to 16);
                W_arr(W_arr'right) <= std_logic_vector(unsigned(delta_1(W_arr(15))) + unsigned(W_arr(10)) + unsigned(W_arr(1)) + unsigned(delta_0(W_arr(2))));
            end if;

        end if;
    end process;


    -- H_gen
    process (clk, reset)
    begin
        if reset = '1' then
            
            H_input <= (others => '0');
            H_initial <= (others => '0');

        elsif rising_edge(clk) then
            
            if (boot='1') then
                H_input <= H_i;
                H_initial <= H_i;
            else
                -- feed iteration
                if cnt_cc="11" then
                    --H_input <= H_sum(H_output, H_input);
                    H_input <= H_output;
                end if;
            end if;

        end if;
    end process;


    process (clk, reset)
    begin
        if reset = '1' then

            cnt_cc <= (others => '0');
            
        elsif rising_edge(clk) then
            
            if (cnt_en='1') then
                cnt_cc <= cnt_cc + 1;
            end if;

            if (start='1') then
                cnt_cc <= (others => '0');
            end if;

        end if;
    end process;

    -- MAIN
    process (clk, reset)
    begin
        if reset = '1' then
            
            boot <= '1';
            cnt_en <= '0';

        elsif rising_edge(clk) then
            
            if (cnt_cc="11") then
                boot <= '0';
            end if;

            if (start='1') then
                boot <= '1';
                cnt_en <= '1';
            end if;

            if ready='1' then
                cnt_en <= '0';
            end if;

        end if;
    end process;

    -- block_o
    -- OLD : block_o <= H_sum(H_initial, H_output_stable);


    block_o <= A_out & B_out & C_out & D_out & E_out & F_out & G_out &  H_out;

    blocko_proc : process (all)
    begin
        --block_o <= H_sum(H_output_stable, H_initial);
        A_out <= std_logic_vector(unsigned(H_initial(1 to 32)) + unsigned(H_output_stable(1 to 32)));
        B_out <= std_logic_vector(unsigned(H_initial(1*32+1 to 1*32+32)) + unsigned(H_output_stable(1*32+1 to 1*32+32)));
        C_out <= std_logic_vector(unsigned(H_initial(2*32+1 to 2*32+32)) + unsigned(H_output_stable(2*32+1 to 2*32+32)));
        D_out <= std_logic_vector(unsigned(H_initial(3*32+1 to 3*32+32)) + unsigned(H_output_stable(3*32+1 to 3*32+32)));
        E_out <= std_logic_vector(unsigned(H_initial(4*32+1 to 4*32+32)) + unsigned(H_output_stable(4*32+1 to 4*32+32)));
        F_out <= std_logic_vector(unsigned(H_initial(5*32+1 to 5*32+32)) + unsigned(H_output_stable(5*32+1 to 5*32+32)));
        G_out <= std_logic_vector(unsigned(H_initial(6*32+1 to 6*32+32)) + unsigned(H_output_stable(6*32+1 to 6*32+32)));
        H_out <= std_logic_vector(unsigned(H_initial(7*32+1 to 7*32+32)) + unsigned(H_output_stable(7*32+1 to 7*32+32)));
    end process;
    
    process (clk, reset)
    begin
        if reset = '1' then
            H_output_stable <= (others => '0');
        elsif rising_edge(clk) then
            if block_end='0' then
                H_output_stable <= H_output;
            end if;
        end if;
    end process;
    

end architecture;