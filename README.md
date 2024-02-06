# Dart Types

A utility to construct and present the type graph of dart type(s).

The tool is useful to visualize and understand the type hierarchy of a certain library or package. 

Currently, the library only supports generating Mermaid graphs. 

### Features:
- Generate the type graph of given dart type(s) or for given library/libraries
- Generate Mermaid code (as code, as url for view, edit or image)
- List all types within a path.

> Note: generics are ignored at the moment

### Installation
- To install the package as a CLI, run the following:
    ```
    dart pub global activate dart_types
    ```

- Available commands in `dart_types`:
    ```
    Global options:
    -h, --help            Print this usage information.
    -v, --[no-]verbose    Verbose output

    Available commands:
    list      List the available types in the given `path`
    mermaid   Generate Mermaid Graph (code, editor url, viewer url, or image url)

    Run "dart_types help <command>" for more information about a command
    ```
- Usage for `dart_types mermaid`
    ```
    Generate Mermaid Graph (code, editor url, viewer url, or image url)

    Usage: dart_types mermaid [arguments]
    -h, --help                    Print this usage information.
    -p, --path                    Specify the path of the file/project where the type(s) are (can be multiple)
    -f, --filter                  filter types using a pattern (can be multiple)
    -x, --[no-]ignore-privates    Ignore all private types


    -t, --type                    scope the type hierarchy to specific type(s) (can be multiple)
    -c, --code                    print the mermaid graph code
    -u, --url                     generate a url to mermaid.live graph viewer
    -e, --url-edit                generate a url to mermaid.live graph editor
    -i, --url-image               generate a url to mermaid.ink graph image
    -g, --graph-type              Specify the graph type: Top Bottom, Bottom Up, Right Left, Left Right
                                [TB, BT, RL, LR (default)]
    ```

> Notes: See the [example](/example/) folder for how to use this as a package

### Example

- Running the following:
    ```console
    dart_types mermaid --path /path/to/flutter/sdk/packages/flutter/lib --code -ignore-privates --type StatelessWidget
    ```
- Produces the code to the following mermaid graph:

    ```mermaid
    %% To view the graph, copy the code below to:
    %%  https://mermaid.live/
    graph LR
        931422573("Object") --> 639058955("Widget")
        639058955 --> 464006715("StatelessWidget")
        639058955 --> 416054233("PreferredSizeWidget")
        464006715 --> 1056914755("Builder")
        464006715 --> 262732828("CallbackShortcuts")
        464006715 --> 337536055("CheckedModeBanner")
        464006715 --> 610219950("Container")
        464006715 --> 936772830("DefaultTextEditingShortcuts")
        464006715 --> 162789820("DisplayFeatureSubScreen")
        464006715 --> 609146547("ExcludeFocus")
        464006715 --> 49112299("ExcludeFocusTraversal")
        464006715 --> 747420043("GestureDetector")
        464006715 --> 146799707("GridPaper")
        464006715 --> 902421044("HeroMode")
        464006715 --> 742478379("HtmlElementView")
        464006715 --> 821894802("Icon")
        464006715 --> 679314("ImageIcon")
        464006715 --> 599778847("IndexedStack")
        464006715 --> 386259944("KeyboardListener")
        464006715 --> 756704846("KeyedSubtree")
        464006715 --> 341174972("ModalBarrier")
        464006715 --> 339198387("NavigationToolbar")
        464006715 --> 409547886("OrientationBuilder")
        464006715 --> 48107699("PageStorage")
        464006715 --> 743848276("Placeholder")
        464006715 --> 456230168("PlatformSelectableRegionContextMenu")
        464006715 --> 42097335("PositionedDirectional")
        464006715 --> 961235098("PreferredSize")
        464006715 --> 1065842558("RawMagnifier")
        464006715 --> 472365102("ReorderableDragStartListener")
        464006715 --> 427683055("SafeArea")
        464006715 --> 286068455("ScrollView")
        464006715 --> 445477711("SingleChildScrollView")
        464006715 --> 126306520("SliverConstrainedCrossAxis")
        464006715 --> 592348889("SliverFillRemaining")
        464006715 --> 83650908("SliverFillViewport")
        464006715 --> 827955045("SliverPersistentHeader")
        464006715 --> 378627107("SliverSafeArea")
        464006715 --> 716412635("SliverVisibility")
        464006715 --> 460084456("Spacer")
        464006715 --> 900189511("Text")
        464006715 --> 535960679("Title")
        464006715 --> 638939478("TwoDimensionalScrollView")
        464006715 --> 661441418("UnconstrainedBox")
        464006715 --> 521488773("View")
        464006715 --> 956347801("ViewAnchor")
        464006715 --> 740469611("Visibility")
        760877175("BoxScrollView") --> 733462125("GridView")
        760877175 --> 167943787("ListView")
        416054233 --> 961235098
        472365102 --> 721803713("ReorderableDelayedDragStartListener")
        286068455 --> 760877175
        286068455 --> 257018606("CustomScrollView")


    style 464006715 color:#7FFF7F

    ```

    > Note: to view the output, paste the graph at: https://mermaid.live 
    >
    > Or alternatively, you can generate a [URL][] directly using the following command:
    > ```
    > dart_types mermaid --path /path/to/flutter/sdk/packages/flutter/lib --url -ignore-privates --type StatelessWidget
    > ```


[URL]: https://mermaid.live/view#pako:eNqFVttuGzcQ_ZWFigAtkNS8LS9-KOCb4iBxI1hO-qIXancssaaWApey5Qb59w5XtmI7uw70YMk8Zzg8c2bIb6Mq1DA6HL15U1yF4tbBXZGWUCyiXS_fFlVY33e_M6qYgw-4HA5nDcKLZUrr9vDgYAVxZV39p3e3cDBrOmrx6XLWFIXhVDBWKv77bPR5_i9UaTb6o3j37q9CckNKbcoSV_5x9QLySqbsFzqYkIIQqWiGTZNN4KFtX8NTSUrBeN5wEuEaYoR66v6DZ5x91I5DSSkNFarL5XjjfA2xF8gkU5xpphF3Yr2f2-pmugwxVZvU9jI4VyXHjHLkkyVUN1BfoJLHtmkG9pCUMGpMSTIjNMm6IaThUimmeUaewrXd-HQF23RWu-Saxet5UTyJNpp1XNeuvb0fg02bCNPNfFpFgKY_O4JCyVIo5J1tK7-pYRyqTf8mwlDKmDEvsFfR3kJsre8lKaEEI0TkAr6HNqd0CgmNE_pVwHSUMYrkjN5HV0_sekgvwgSjRAhEnkMMuRADKTChNFc58fO08mceVtCkr9gbvXjNqDZCE4b4D1UYUE7lXsiIlV3AIKzEsyitO4E_NDVs0b0JbdbvLi0ZEroTfYT7ebCx_uTaBEOWUaVURGghdwSMvZknLHZ_dEGpEkblY6FW1h_bGN1AZM4NNZrrnPff9tYtbHKhuQoBm6SfIYhBH2mdc_mMcdHqmfJa_wlNiZKdoSYo4hQ9gX8Gasi10Ezl6BNvK1iG4bClZJxQqXfYdB3iaoqDpkp27uESFphWbkVsrgtoNv0xGDGK89znk9C6fBKoT13EIPh1wOtGUsZLYvTLYTUwpmSpBSvLDL-0dxd20bjroYIIxbgsaWfKSwgRD59Pc4qKoaFietUnAoXDwdKNram9hqMItn8iakmkFjtgFYP3g10iBJZbKUozFAeUh5MllvoXLMokx3N3g2qaL5iIlWhTzGOxPomhbY-2rh1oJcaF1trsqWPn_SXgXdXg_v2tjJoRQ_QzSk5ujdN0oPkV3j1ElHvKBIdbJ246BzvkOa6wdxXtxtaO9qrOikqRpfixy1fXurnzLt33qy0J0Sh59v90jf4fmokEZ1fZFSVfHv1C8tJgmbt5eOWS77en5Npwgx2dUXfh1OHMbDvv_6LEUlIhqKCZ-KWpfpT3OGz782EU66q6R8VgVFNKjskQ-gA6aqrlwBWiBBESe3EHfSGrkgS3oqp7G4Tts7Ps2JwLySgrHy6gJxntuQ93rjIC655LnrvvaeqPr5bnY6Fbeuzj3WZ41RCuKH_R1YAXOM6bgebed-kuxmNWPy_hSw39gP_Jj49Nm8LqRe3yp033Hp5IWAUf4uFvajweq_GsGb0dPTwIR4ffRvh2XOXnZW3jzej79_8BnFvShg==


### Known Limitation:

- Generics are ignored in generated graphs (in terms of type hierarchy)
- Types from external libraries may not appear in the graph as super types in certain cases.
    - I assume that the analyzer will take advantage of cached analysis to provide super types from external libraries. If those external libraries are not available in the cache, they are ignored (this is unverified observation).
- Note: mermaid.live website has a limit of 500 edges. 

<!--  TODO: 
- I think it would be more useful if the nodes provided more information. For example, if clicking in the node shows the documentation of the type with a URI to where it's located. 

- Graphviz Implementation 
 -->
