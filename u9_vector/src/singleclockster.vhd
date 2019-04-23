library ieee;
    use ieee.std_logic_1164.all;

-- ====================================================================
--                         VECTOR-06C FPGA REPLICA
--
-- 					Copyright (C) 2007, Viacheslav Slavinsky
--
-- This core is distributed under modified BSD license. 
-- For complete licensing information see LICENSE.TXT.
-- -------------------------------------------------------------------- 
--
-- An open implementation of Vector-06C home computer
--
-- Author: Viacheslav Slavinsky, http://sensi.org/~svo
-- 
-- Design File: singleclockster.v
--
-- Generate single CPU clocks for key-tapped code execution.
--
-- --------------------------------------------------------------------

--`default_nettype none

entity singleclockster is
    port (
        clk24                : in std_logic;
        singleclock_enabled  : in std_logic;
        n_key                : in std_logic;
        singleclock          : out std_logic
    );
end singleclockster;

architecture trans of singleclockster is
    
    signal key1_nreleased    : std_logic;
    
    -- Declare intermediate signals for referenced outputs
    signal singleclock_xhdl0 : std_logic;
begin
    -- Drive referenced outputs
    singleclock <= singleclock_xhdl0;
    process (clk24)
    begin
        if (clk24'event and clk24 = '1') then
            if (singleclock_enabled = '1') then
                if (n_key = '0') then
                    if ((not(key1_nreleased)) = '1') then
                        singleclock_xhdl0 <= '1';
                        key1_nreleased <= '1';
                    end if;
                else
                    
                    key1_nreleased <= '0';
                end if;
                if (singleclock_xhdl0 = '1') then
                    singleclock_xhdl0 <= '0';
                end if;
            end if;
        end if;
    end process;
    
    
end trans;


