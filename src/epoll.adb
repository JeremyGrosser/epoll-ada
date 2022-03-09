--
--  Copyright (C) 2022 Jeremy Grosser <jeremy@synack.me>
--
--  SPDX-License-Identifier: BSD-3-Clause
--
package body Epoll is

   function epoll_create1
      (flags : int)
      return Epoll_Descriptor
   with Import        => True,
        Convention    => C,
        External_Name => "epoll_create1";

   function epoll_ctl
      (epfd  : Epoll_Descriptor;
       op    : Epoll_Operation;
       fd    : int;
       event : access Epoll_Event)
       return int
   with Import        => True,
        Convention    => C,
        External_Name => "epoll_ctl";

   function epoll_wait
      (epfd      : Epoll_Descriptor;
       events    : System.Address;
       maxevents : int;
       timeout   : int)
       return int
   with Import        => True,
        Convention    => C,
        External_Name => "epoll_wait";

   function Create
      return Epoll_Descriptor
   is
   begin
      return epoll_create1 (0);
   end Create;

   procedure Control
      (This   : Epoll_Descriptor;
       Socket : Socket_Type;
       Op     : Epoll_Operation;
       Event  : access Epoll_Event)
   is
   begin
      if epoll_ctl (This, Op, int (To_C (Socket)), Event) = -1 then
         raise Epoll_Error;
      end if;
   end Control;

   function Wait
      (This       : Epoll_Descriptor;
       Max_Events : Positive := 1;
       Timeout    : Integer := -1)
       return Epoll_Events
   is
      E      : aliased Epoll_Events (1 .. Max_Events);
      Status : int;
   begin
      Status := epoll_wait (This, E'Address, int (Max_Events), int (Timeout));
      if Status = -1 then
         raise Epoll_Error;
      end if;
      return E (E'First .. Integer (Status));
   end Wait;

end Epoll;
