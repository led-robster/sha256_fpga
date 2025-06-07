

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;

entity top is
    port (
        clk   : in std_logic;
        reset : in std_logic
    );
end entity top;




architecture rtl of top is


    signal s_clear : std_logic;
    signal s_run : std_logic;
    signal s_wr : std_logic;
    signal s_wmask : unsigned(1 to 512);
    signal s_address : std_logic_vector(0 to 3);
    signal s_wdata : std_logic_vector(1 to 512);
    signal s_valid : std_logic;
    signal s_hash : std_logic_vector(1 to 256);
    signal s_error : std_logic;

    signal hash : std_logic_vector(1 to 256);

    -- SYNTHESIS ATTRIBUTES
    attribute syn_noprune : boolean;
    attribute syn_noprune of sha256_encode_inst : label is true; 


begin


    sha256_encode_inst : entity work.sha256_encode(rtl)
    port map (
        clk     => clk,
        reset   => reset,
        clear   => s_clear, 
        run     => s_run, -- impulse
        wr      => s_wr, -- impulse
        wmask   => s_wmask, 
        error   => s_error,
        -- data in
        address => s_address,
        wdata   => s_wdata,
        -- data out
        valid   => s_valid,
        hash    => s_hash
    );


    process (clk, reset)
    begin
        if reset = '1' then
            s_clear     <= '0';                                    
            s_run       <= '0';                                    
            s_wr        <= '0';                                    
            s_wmask     <= (others => '0');                                    
            s_address   <= (others => '0');                                    
            s_wdata     <= (others => '0');                                    
        elsif rising_edge(clk) then
            
            s_run <= '0';
            
            if s_valid='1' then
                hash <= s_hash; 
            end if;
        end if;
    end process;

    

end architecture;