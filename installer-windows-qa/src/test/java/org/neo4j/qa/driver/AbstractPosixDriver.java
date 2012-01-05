/**
 * Copyright (c) 2002-2011 "Neo Technology,"
 * Network Engine for Objects in Lund AB [http://neotechnology.com]
 *
 * This file is part of Neo4j.
 *
 * Neo4j is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
package org.neo4j.qa.driver;

import java.util.List;

import org.neo4j.vagrant.SSHShell;
import org.neo4j.vagrant.VirtualMachine;

public abstract class AbstractPosixDriver implements Neo4jDriver {

    protected VirtualMachine vm;
    protected SSHShell sh;
    private Neo4jServerAPI serverAPI;

    public AbstractPosixDriver(VirtualMachine vm)
    {
        this.vm = vm;
    }

    @Override
    public void close() {
        if(sh != null) sh.close();
    }   

    @Override
    public VirtualMachine vm()
    {
        return vm;
    }

    @Override
    public void up() {
        vm.up();
        sh = vm.ssh();
    }
    
    @Override
    public void reboot() {
        sh.close();
        vm.halt();
        up();
    }
    
    @Override
    public void destroyDatabase() {
        sh.run("rm -rf " + installDir() + "/data/graph.db");
    }

    @Override
    public Neo4jServerAPI api() {
        if(serverAPI == null) {
            System.out.println("http://" + vm().definition().ip() + ":7474");
            serverAPI = new Neo4jServerAPI("http://" + vm().definition().ip() + ":7474");
        }
        return serverAPI;
    }
    
    //
    // File management
    //
    
    @Override
    public String readFile(String path) {
        return sh.run("cat", path).getOutput();
    }
    
    @Override
    public List<String> listDir(String path) {
        return sh.run("ls", path).getOutputAsList();
    }
    
    @Override
    public void writeFile(String contents, String path) {
        sh.run("echo '"+contents+"' > " + path);
    }

    @Override
    public void setConfig(String configFilePath, String key, String value) {
        // Remove any pre-existing config directive for this key, then append
        // the new setting at the bottom of the file.
        sh.run("sed -i 's/^"+key+"=.*//g' "+configFilePath+" && echo " + key + "=" + value + " >> " + configFilePath);
    }
    
}
