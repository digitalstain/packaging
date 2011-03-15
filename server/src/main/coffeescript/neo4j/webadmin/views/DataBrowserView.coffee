###
Copyright (c) 2002-2011 "Neo Technology,"
Network Engine for Objects in Lund AB [http://neotechnology.com]

This file is part of Neo4j.

Neo4j is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
###

define(
  ['neo4j/webadmin/data/Search',
   'neo4j/webadmin/data/ItemUrlResolver',
   'neo4j/webadmin/security/HtmlEscaper',
   './databrowser/TabularView',
   './databrowser/VisualizedView',
   './databrowser/CreateRelationshipDialog',
   'neo4j/webadmin/templates/databrowser/base','lib/backbone'], 
  (Search, ItemUrlResolver, HtmlEscaper, TabularView, VisualizedView, CreateRelationshipDialog, template) ->

    class DataBrowserView extends Backbone.View
      
      template : template

      events : 
        "keyup #data-console" : "search"
        "click #data-create-node" : "createNode"
        "click #data-create-relationship" : "createRelationship"
        "click #data-switch-view" : "switchView"

      initialize : (options)->
        @dataModel = options.dataModel
        @server = options.state.getServer()

        @htmlEscaper = new HtmlEscaper

        @urlResolver = new ItemUrlResolver(@server)
        
        @dataModel.bind("change:query", @queryChanged)
        @switchToTabularView()

      render : =>
        $(@el).html @template( 
          query : @htmlEscaper.escape(@dataModel.getQuery())
          viewType : @viewType )
        @renderDataView()

      renderDataView : =>
        $("#data-area", @el).empty().append @dataView.el
        @dataView.render()
        return this

      queryChanged : =>
        $("#data-console",@el).val(@dataModel.getQuery())

      search : (ev) =>
        @dataModel.setQuery( $("#data-console",@el).val() )

      createNode : =>
        @server.node({}).then (node) =>
          id = @urlResolver.extractNodeId(node.getSelf())
          @dataModel.setData( node, true, {silent:true} ) 
          @dataModel.setQuery( id, true) 

      createRelationship : =>
        if @createRelationshipDialog?
          @hideCreateRelationshipDialog()
        else
          button = $("#data-create-relationship")
          button.addClass("selected")
          @createRelationshipDialog = new CreateRelationshipDialog(
            baseElement : button
            dataModel : @dataModel
            server : @server
            closeCallback : @hideCreateRelationshipDialog)

      hideCreateRelationshipDialog : =>
        if @createRelationshipDialog?
          @createRelationshipDialog.remove()
          delete(@createRelationshipDialog)
          $("#data-create-relationship").removeClass("selected")


      switchView : (ev) =>
        if @viewType == "visualized"
          $(ev.target).removeClass("tabular")
          @switchToTabularView()
        else
          $(ev.target).addClass("tabular")
          @switchToVisualizedView()
        
        @renderDataView()
          

      switchToVisualizedView : =>
        if @dataView?
          @dataView.remove()
        @viewType = "visualized"
        @dataView = new VisualizedView(dataModel:@dataModel, server:@server)

      switchToTabularView : =>
        if @dataView?
          @dataView.remove()
        @viewType = "tabular"
        @dataView = new TabularView(dataModel:@dataModel, server:@server)

)
