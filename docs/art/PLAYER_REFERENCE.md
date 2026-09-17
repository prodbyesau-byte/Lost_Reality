# Reference-driven player outfit

The user's `pictures/player.png` guides the player: tousled brown hair, an open charcoal-brown hoodie over a grey T-shirt, faded dark jeans, canvas sneakers with pale soles/laces, and a worn brown backpack with padded shoulder straps.

This is a stylized procedural 3D interpretation for the existing elevated game camera. It does not reproduce the reference's photorealistic face, fabric simulation or hair strands. The source image is a visual reference, not a texture projected onto the character.

`art/meshes/player_outfit.gd` owns the new cosmetic geometry. `HumanVisual` retains its existing leg/arm/knee/elbow motion. Player-specific materials are isolated under `player_*` IDs so world furniture and other fabric surfaces are unaffected. The backpack is cosmetic; no inventory, equipment, stat bonus or save field is added.

`tests/player_visual_review.tscn` renders the actual character from three sides. It runs with the full regression suite. Player physics, movement, camera, save data and progression are unchanged.
