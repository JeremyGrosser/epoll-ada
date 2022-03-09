--
--  Copyright (C) 2022 Jeremy Grosser <jeremy@synack.me>
--
--  SPDX-License-Identifier: BSD-3-Clause
--
with Ada.Text_IO; use Ada.Text_IO;
with Interfaces;

package body Server is

   use GNAT.Sockets;

   Listen_Backlog : constant := 128;

   function Hash (Element : GNAT.Sockets.Socket_Type)
      return Ada.Containers.Hash_Type
   is
   begin
      return Ada.Containers.Hash_Type (To_C (Element));
   end Hash;

   function "=" (Left, Right : GNAT.Sockets.Socket_Type)
      return Boolean
   is (To_C (Left) = To_C (Right));

   procedure Bind
      (Server     : in out Socket_Server;
       Host       : String;
       Port       : String)
   is
      Non_Blocking : Request_Type := (Name => Non_Blocking_IO, Enabled => True);
      Acceptable   : aliased Epoll.Epoll_Event :=
         (Flags =>
            (Readable => True,
             Error    => True,
             others   => False),
          others => <>);
      Addresses    : constant Address_Info_Array := Get_Address_Info
         (Host    => Host,
          Service => Port,
          Passive => True);
      Socket : Socket_Type;
   begin
      Acceptable.Flags.Readable := True;

      for Addr of Addresses loop
         if Host = "" and Addr.Addr.Family = Family_Inet6 then
            null;
         else
            Put_Line ("Bind " & Image (Addr.Addr));
            Create_Socket
               (Socket, Addr.Addr.Family, Addr.Mode, Addr.Level);
            Set_Socket_Option
               (Socket, Socket_Level, (Reuse_Address, True));
            Set_Socket_Option
               (Socket, IP_Protocol_For_TCP_Level, (No_Delay, True));
            Control_Socket
               (Socket, Non_Blocking);
            Bind_Socket
               (Socket, Addr.Addr);
            Listen_Socket
               (Socket, Listen_Backlog);

            Acceptable.Data := Interfaces.Unsigned_64 (To_C (Socket));
            Epoll.Control (Server.EP, Socket, Epoll.Add, Acceptable'Access);
            Socket_Sets.Insert (Server.Listeners, Socket);
         end if;
      end loop;
   end Bind;

   procedure Listener_Event
      (Server : in out Socket_Server;
       Socket : Socket_Type;
       Event  : Epoll.Epoll_Event)
   is
      E : aliased Epoll.Epoll_Event :=
         (Flags =>
            (Readable => (Server.On_Readable /= null),
             Writable => (Server.On_Writable /= null),
             One_Shot => False,
             Hang_Up  => True,
             Error    => True,
             others   => False),
          others => <>);
      Client_Socket  : Socket_Type;
      Client_Address : Sock_Addr_Type;
   begin
      if Event.Flags.Readable then
         Accept_Socket (Socket, Client_Socket, Client_Address);
         Put_Line ("Accepted connection from " & Image (Client_Address));

         E.Data := Interfaces.Unsigned_64 (To_C (Client_Socket));
         Epoll.Control (Server.EP, Client_Socket, Epoll.Add, E'Access);
         Server.Sessions.Insert (Client_Socket);

         if Server.On_Connect /= null then
            if Server.On_Connect.all (Client_Socket) = Should_Close then
               Epoll.Control (Server.EP, Client_Socket, Epoll.Delete, null);
               Close_Socket (Client_Socket);
               Server.Sessions.Delete (Client_Socket);
               return;
            end if;
         end if;
      end if;

      if Event.Flags.Error then
         Put_Line ("Listener socket error!");
         Epoll.Control (Server.EP, Socket, Epoll.Delete, null);
         Close_Socket (Socket);
         Server.Listeners.Delete (Socket);
      end if;
   end Listener_Event;

   procedure Session_Event
      (Server : in out Socket_Server;
       Socket : Socket_Type;
       Event  : Epoll.Epoll_Event)
   is
   begin
      if Event.Flags.Readable and Server.On_Readable /= null then
         if Server.On_Readable.all (Socket) = Should_Close then
            Epoll.Control (Server.EP, Socket, Epoll.Delete, null);
            Close_Socket (Socket);
            Server.Sessions.Delete (Socket);
            Put_Line ("Socket closed by reader");
            return;
         end if;
      end if;

      if Event.Flags.Writable and Server.On_Writable /= null then
         if Server.On_Writable.all (Socket) = Should_Close then
            Epoll.Control (Server.EP, Socket, Epoll.Delete, null);
            Close_Socket (Socket);
            Server.Sessions.Delete (Socket);
            Put_Line ("Socket closed by writer");
            return;
         end if;
      end if;

      if Event.Flags.Hang_Up then
         Epoll.Control (Server.EP, Socket, Epoll.Delete, null);
         Close_Socket (Socket);
         Server.Sessions.Delete (Socket);
         Put_Line ("Socket closed by client");
      end if;

      if Event.Flags.Error then
         Epoll.Control (Server.EP, Socket, Epoll.Delete, null);
         Close_Socket (Socket);
         Server.Sessions.Delete (Socket);
         Put_Line ("Socket closed by error");
      end if;
   end Session_Event;

   procedure Poll
      (Server : in out Socket_Server)
   is
      Socket : Socket_Type;
   begin
      for Event of Epoll.Wait (Server.EP, Max_Events => 128) loop
         Socket := To_Ada (Integer (Event.Data));
         if Server.Listeners.Contains (Socket) then
            Listener_Event (Server, Socket, Event);
         elsif Server.Sessions.Contains (Socket) then
            Session_Event (Server, Socket, Event);
         else
            Put_Line ("Got event for unknown socket descriptor: " & Image (Socket));
         end if;
      end loop;
   end Poll;

   procedure Destroy
      (Server : in out Socket_Server)
   is
      use Socket_Sets;
   begin
      for Socket of Server.Listeners loop
         Close_Socket (Socket);
      end loop;
      Clear (Server.Listeners);

      for Socket of Server.Sessions loop
         Close_Socket (Socket);
      end loop;
      Clear (Server.Sessions);
      --  Epoll.Close (Server.EP);
   end Destroy;

end Server;
