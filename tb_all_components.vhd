LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
 
ENTITY tb_all_components IS
END tb_all_components;
 
ARCHITECTURE behavior OF tb_all_components IS 

    COMPONENT all_components
    PORT(
         col : IN  std_logic_vector(3 downto 0);
         clk : IN  std_logic;
         rst : IN  std_logic;
			row   : OUT STD_LOGIC_VECTOR(3 downto 0);
         selector : OUT  std_logic_vector(3 downto 0);
         digitos : OUT  std_logic_vector(6 downto 0);
         pd : OUT  std_logic
        );
    END COMPONENT;

   --Inputs
   signal col : std_logic_vector(3 downto 0) := (others => '0');
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';

 	--Outputs
	signal row : STD_LOGIC_VECTOR(3 downto 0);
   signal selector : std_logic_vector(3 downto 0);
   signal digitos : std_logic_vector(6 downto 0);
   signal pd : std_logic;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: all_components PORT MAP (
          col => col,
          clk => clk,
          rst => rst,
			 row => row,
          selector => selector,
          digitos => digitos,
          pd => pd
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      
		rst <= '0';
		wait for 100 ns;
		rst <= '1';
		
		wait until row = "0010";  -- Esperar la fila 4
		col <= "0010"; -- Pulse 9
		wait for 90 ms;
		
		col <= "0000";
		wait for 50 ns;
		
		wait until row = "0010";  -- Esperar la fila 3
		col <= "0010";  -- Pulse el 9
		wait for 90 ms;  
		
		col <= "0000";
		wait for 50 ns;
		
		wait until row = "1000";  -- Esperar la fila 4
		col <= "0001";  -- Pulse A
		wait for 90 ms;  
		
		col <= "0000";
		wait for 50 ns;
		
		wait until row = "0010";  -- Esperar la fila 3
		col <= "0010";  -- Pulse el 9
		wait for 90 ms;   
		
		col <= "0000";
		wait for 50 ns;
		
		wait until row = "0010";  -- Esperar la fila 3
		col <= "0010";  -- Pulse el 9
		wait for 90 ms;  
		
		col <= "0000";
		wait for 50 ns;
		
		wait until row = "1000";  -- Esperar la fila 4
		col <= "0001";  -- Pulse A
		wait for 90 ms;   

		col <= "0000";
      wait;
   end process;

END;
