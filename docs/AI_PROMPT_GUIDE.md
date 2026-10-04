ASCEND Sword Prompt Reference
1. Universal rules (all three types)

Output goal. A clean xianxia-style low-poly sword concept image, used as input to Meshy. The quality bar is a "hero-tier item in a stylized cultivation RPG." It must not look like a toy, a flat sticker, or a Western crusader sword.

Framing

One sword, floating upright and centered, blade up and hilt down.
Seen straight from the front, with no perspective and no rotation.
Plain solid dark navy background.
Nothing else in frame: no ground, shadow, hands, scabbard, or props.
The sword fills most of the vertical frame, with a small margin top and bottom.
Aspect ratio: 3:4.

Surface and lighting (the Meshy-safe rules)

Matte hand-painted metal with soft tonal variation in broad patches and slightly worn, lighter edges.
No gloss, no specular highlights, no glints, no streaks, no reflections, no rim light, no glow.
Lighting is soft, even, and neutral, as if previewing the base-color texture. No cast shadows.
All shapes use crisp, chamfered, angular facets, never rounded or bubbly forms.
Gold is a matte painted gold, never mirror-polished.
Depth comes from a value ladder: raised surfaces are lighter and recesses are darker. It never comes from highlights.

Style: sharp xianxia

Guards are slim and swept, and every end tapers to a needle point.
Pommels are faceted teardrop or diamond caps, or a faceted gem-capped sphere for Epic and above.
Grips are slender, with a diagonal crisscross wrap and thin ring collars.
Blade relief is built into the geometry as thin, sharp, long shapes (ridge, bevels, groove, chevrons), never as painted stripes.
No hearts, flowers, spirals, scallops, discs, stepped pyramids, or ball pommels.

Palette: muted colors (steel, slate, ivory, antique gold, ink-blue, violet-black), with saturation saved for small gems or inlays.

2. Tier ladder
Tier	Blade	Guard	Gems	Pommel
Common	Ridge and bevel only	Plain, short, straight tapered bar	None	Small plain faceted cap
Uncommon	Ridge, bevels, and a thin groove	Slim, sharply tapered, with exactly ONE accent	None	Sharp faceted teardrop
Rare	Carved thin lines or a panel in relief	Layered or hub guard, swept to needle points	None (flat inlays only)	Teardrop with a thin metal band
Epic	Rich relief plus a second material	Sculpted guard	Yes, faceted and flat-colored, in bezels	Faceted sphere with a small gem
Legendary	Full layered relief	Boldest silhouette in the set	Most gems	Large faceted sphere with a gem
3. Type structures
DAO — single-edged, straight slab, chisel tip
Edge: left side sharp, right side a thick unsharpened spine.
Silhouette: a perfectly straight slab with parallel edges and no curve or taper.
Tip: ONE straight diagonal chisel cut at 30-35°, with the sharp point at the top RIGHT.
Proportions (target values, see section 5): blade length about 8.5× its width; whole sword about 11-11.5× blade width; blade about 66-68% of total length; grip 2.2-2.5× blade width; pommel 1.0-1.4× blade width.
Guard vocabulary (keep these distinct per tier):
Common is a short straight tapered bar.
Rare is two stacked tapered bars with trailing ends.
Legendary (locked) is stacked octagon plates.
Spine fins (three sharp triangles) are Legendary only.
Avoid: curves, a willow-leaf belly, an angled kissaki, scallops, a greatsword look.
Reference to attach: the locked #9 dao.
JIAN — double-edged, symmetric, straight
Edges: both long sides sharp. The blade is perfectly symmetric left to right.
Silhouette: the first 85% is straight and nearly parallel, then the last 15% is a short, steep, centered triangular point. It must not be a long arrow tip.
Width: about 70% as wide as the original wide reference blade. This keeps it sturdy but clearly not a greatsword.
Proportions: blade length about 10.5× its width; whole sword about 13-13.5× blade width; blade about 68% of total; crossguard 2.9-3.8× blade width (grows with tier); grip about 2.5×; pommel 1.2-1.4×.
Guard vocabulary (each jian has its own):
Uncommon: a flat straight bar (#3) or a swept wing bar (#4).
Rare: a swept bar with a diamond hub (#6).
Epic: a mountain-ridge guard (#8).
Legendary (locked): wings, tiers, a central crest, and gems.
Avoid: a thin rapier look, a long arrow tip, a crossbar-and-ball-pommel look.
Reference to attach: the locked #10 jian.
CUTLASS — short, wide crescent
Edge: the convex side is sharp and the other side is a thick spine.
Silhouette: a clear crescent. The centerline deviates about one blade-width from straight at the deepest point, and the blade is widest in the middle. The final fifth has a clipped-back tip where the spine cuts diagonally down to the edge.
Proportions: length along the curve about 5× the widest width; whole sword about 6.3× crossguard width; blade about 70% of total; grip about as long as the crossguard is wide.
Hilt: slim D-shaped knuckle bow built from straight angular segments (not a smooth loop), and a slim tapered crossguard.
Signature feature: each cutlass gets ONE (#7 has the hollow ring). Common has none.
Avoid: a cleaver or machete look, a pirate-prop look, a basket guard.
Reference to attach: the locked #7 result.
4. The 10-sword roster
#	Sword	Tier	Type	Signature	Palette
1	Iron Reed	Common	Dao	Plain	Slate gray, pale green-tan grip
2	Bronze Discipline	Common	Cutlass	Plain	Bronze-gray
3	Earthbound Steel	Uncommon	Jian	Green base band, straight bar guard	Cool steel, sage green
4	Wandering Blade	Uncommon	Jian	Swept-wing guard	Dulled steel, tan
5	Crane Amidst Clouds	Rare	Dao	Cloud-wisp lines, layered guard	Silver-white, blue-gray, navy
6	Resonant Heart	Rare	Jian	Chevron "pulse" lines, diamond hub	Slate ink-blue, silver
7	Hollow Moon	Epic	Cutlass	Crescent relief, hollow ring, horns (locked)	Lavender-silver, violet-black
8	Ascendant Gold	Epic	Jian	Rising rays, mountain-ridge guard	Champagne gold, violet-black, violet gems
9	Void Purity	Legendary	Dao	Ivory diamond panel, spine fins (locked)	Charcoal, ivory, antique gold, ice-white gem
10	Heaven-Piercing	Legendary	Jian	Chevron ridge, winged guard (locked)	White-gold, amber gems

Tier lore, materials, and colors are not in the repo. The design paragraphs are my proposals, so correct any that don't match your lore. If you have the lore, send it and I'll update this table.

5. Calibration notes (measured by eye on your screenshots)

Gemini tends to widen blades and ignore ratios in the prompt:

Asked for a dao ratio of 8.5 and got about 5.4. Asked for 7.5 and got about 7.
Asked for a jian ratio of 9 and got about 6.4.
Adding a reference image widens the blade further.

Practical rules:

Ask for a longer, narrower blade than you want. The prompts above already do this.
Use relative wording against the reference ("about 70% of its width") as well as numbers.
If a blade comes out too wide, say "make the blade 25% narrower and 10% longer" in a follow-up and keep everything else identical.
6. Gemini setup
Model: 3.1 Pro with Extended thinking.
Aspect ratio: 3:4 (9:16 if the sword looks small).
Always attach the reference images, with the order stated in the prompt.
Fix problems with short follow-up edits in the same chat before regenerating.
I couldn't verify how Gemini's picker maps to its image models, so treat this as tested-by-you, not confirmed.
7. Prompt skeleton (fixed section order)
text
1. Intro: "Create a [premium/clean], game-ready weapon concept image of a single fantasy xianxia [TYPE]... for use as input to an image-to-3D tool. Quality bar: [TIER description]. Must NOT look like a toy..."
2. Reference image(s): what to copy (silhouette/proportions/finish) and what to ignore (colors, guard, gems, pommel)
3. Size class: one-handed, NOT a greatsword/buster sword
4. Framing: upright, centered, front-facing, plain navy background
5. Blade silhouette: type-specific shape and ratios
6. Blade sculpting: relief built into the geometry, by tier
7. Materials and colors: value ladder, muted palette, accent rules by tier
8. Surface and lighting: the matte/no-shine block (copy verbatim)
9. Hilt: guard, grip, pommel, with ratios in blade-widths
10. Avoid: type- and tier-specific list
8. Common failure modes and fixes
Symptom	Likely fix
Shiny or glossy blade	Repeat the no-shine block, and say "base-color texture preview"
Greatsword look	Narrow the blade, enlarge the guard, lengthen the grip
Toy or plastic look	Add "muted palette," "chamfered facets," and "worn edges"; remove saturated flat colors
Guard looks like a Western crossbar	Describe needle-point tapering, then name the shapes to avoid
Gems blur into circles	Say "faceted, flat-colored, in a bezel"; reduce the count
Fine details vanish or merge	Make the shapes bigger and fewer
A dao looks like a katana	Restate the chisel cut and straight parallel edges
Arrow-shaped jian tip	Restate "short, steep, last 15 percent"
Reference is copied too closely