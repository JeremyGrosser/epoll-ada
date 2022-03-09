--
--  Copyright (C) 2022 Jeremy Grosser <jeremy@synack.me>
--
--  SPDX-License-Identifier: BSD-3-Clause
--
with Interfaces.C; use Interfaces.C;
with Interfaces;   use Interfaces;
with GNAT.Sockets; use GNAT.Sockets;

package Epoll is

   Epoll_Error : exception;

   type Epoll_Descriptor is private;

   type Epoll_Flags is record
      Readable       : Boolean; --  EPOLLIN
      Writable       : Boolean; --  EPOLLOUT
      Peer_Shutdown  : Boolean; --  EPOLLRDHUP
      Out_Of_Band    : Boolean; --  EPOLLPRI
      Error          : Boolean; --  EPOLLERR
      Hang_Up        : Boolean; --  EPOLLHUP
      Edge_Triggered : Boolean; --  EPOLLET
      One_Shot       : Boolean; --  EPOLLONESHOT
      Wake_Up        : Boolean; --  EPOLLWAKEUP
      Exclusive      : Boolean; --  EPOLLEXCLUSIVE
   end record
      with Size => 32;
   for Epoll_Flags use record
      Readable         at 0 range 0 .. 0;
      Out_Of_Band      at 0 range 1 .. 1;
      Writable         at 0 range 2 .. 2;
      Error            at 0 range 3 .. 3;
      Hang_Up          at 0 range 4 .. 4;
      Peer_Shutdown    at 0 range 13 .. 13;
      Exclusive        at 0 range 28 .. 28;
      Wake_Up          at 0 range 29 .. 29;
      One_Shot         at 0 range 30 .. 30;
      Edge_Triggered   at 0 range 31 .. 31;
   end record;

   type Epoll_Event is record
      Flags : Epoll_Flags := (others => False);
      Data  : Unsigned_64 := -1;
   end record
      with Pack,
           Convention => C_Pass_By_Copy;

   type Epoll_Events is array (Integer range <>) of Epoll_Event
      with Convention => C;

   type Epoll_Operation is (Add, Delete, Modify)
      with Size => 32;
   for Epoll_Operation use (1, 2, 3);

   function Create
      return Epoll_Descriptor;

   procedure Control
      (This   : Epoll_Descriptor;
       Socket : Socket_Type;
       Op     : Epoll_Operation;
       Event  : access Epoll_Event);

   function Wait
      (This       : Epoll_Descriptor;
       Max_Events : Positive := 1;
       Timeout    : Integer := -1)
       return Epoll_Events;

private

   type Epoll_Descriptor is new int;

end Epoll;
