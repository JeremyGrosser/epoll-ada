--
--  Copyright (C) 2022 Jeremy Grosser <jeremy@synack.me>
--
--  SPDX-License-Identifier: BSD-3-Clause
--
with Ada.Containers.Hashed_Sets;
with Ada.Containers.Vectors;
with Ada.Containers;
with GNAT.Sockets;
with Epoll;

package Server is

   function Hash (Element : GNAT.Sockets.Socket_Type)
      return Ada.Containers.Hash_Type;

   function "=" (Left, Right : GNAT.Sockets.Socket_Type)
      return Boolean;

   package Socket_Sets is new Ada.Containers.Hashed_Sets
      (Element_Type        => GNAT.Sockets.Socket_Type,
       Equivalent_Elements => "=",
       Hash                => Hash);

   type Socket_Action is (No_Action, Should_Close);
   type Callback is access function
       (Socket : GNAT.Sockets.Socket_Type)
       return Socket_Action;

   type Socket_Server is record
      On_Connect  : Callback := null;
      On_Readable : Callback := null;
      On_Writable : Callback := null;
      Listeners   : Socket_Sets.Set := Socket_Sets.Empty_Set;
      Sessions    : Socket_Sets.Set := Socket_Sets.Empty_Set;
      EP          : Epoll.Epoll_Descriptor := Epoll.Create;
   end record;

   procedure Bind
      (Server     : in out Socket_Server;
       Host       : String;
       Port       : String);

   procedure Poll
      (Server : in out Socket_Server);

   procedure Destroy
      (Server : in out Socket_Server);

private

   procedure Listener_Event
      (Server : in out Socket_Server;
       Socket : GNAT.Sockets.Socket_Type;
       Event  : Epoll.Epoll_Event);

   procedure Session_Event
      (Server : in out Socket_Server;
       Socket : GNAT.Sockets.Socket_Type;
       Event  : Epoll.Epoll_Event);
end Server;
