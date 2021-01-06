# Export

You can access the export screen

- by selecting `File` menu and then `Export tree as...`
- by pressing F2

The screen displayed is similar to the image:

![Export screen](./images/export.jpg)

The parameters you can change are explained below.

- `Exported file name`: any valid windows file name without the extension.
- `Title`: the title will be shown at the top of the file.
- `Max export level`: the routines with a depth level less or equal than this are exported. The root routine has a level of 1, the root's children routines have a level of 2 etc.
- `Output format`: the type of file name created (see [Output formats](#output-formats)).

## Export all vs export only visible

?> If you want to export all the routines press the button `All`

![button All](./images/button_all.jpg)

?> If you want to export only the visible routines press the button `What you see`

![button visible](./images/button_visible.jpg)

## Bookmark and export

If you want to export a range of consecutive routines you can bookmark the **first** and the **last** (or the first only) by selecting them and pressing `F11` and then pressing the button `Selected`.

## Output formats

### Web tree with source code

![Web tree](./images/export_as_web_tree.jpg)

#### Searching the source code

By selecting (**left click**) a routine in the left panel the right panel is synchronized to show the selected routine.

By **right clicking** a routine the right panel shows only the selected routine.

`Control F` : opens browser search field to find a routine, word or anything else.

#### Buttons in web page

![decrease_increase](./images/decrease_increase.jpg)
Make the left panel narrower and the right panel wider and conversely.

![show_all_code](./images/show_all_code.jpg)
Refreshes the page.

![expand_collapse_all](./images/expand_collapse_all.jpg)
Unfold and fold all routines.

![expand_collapse_level](./images/expand_collapse_level.jpg)
Unfold and fold current routine, it's siblings and all under it.

### Vertical web flowchart

![Vertical web flowchart](./images/export_as_vertical_flowchart.jpg)

### Horizontal web flowchart

![Horizontal web flowchart](./images/export_as_horizontal_flowchart.jpg)

### Vertical powerpoint flowchart

![Vertical powerpoint flowchart](./images/export_as_vertical_powerpoint_flowchart.jpg)

### Text tree

![Text tree](./images/export_as_text_tree.jpg)

### Text tree for AS400

It is the same as plain text but the connectors `├─ └─` are replaced by plain characters `|_ \_`, so the tree can be inserted into the source member without problems.

![Text tree for AS400](./images/export_as_text_tree_AS400.jpg)
