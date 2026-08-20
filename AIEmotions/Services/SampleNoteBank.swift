//
//  SampleNoteBank.swift
//  AIEmotions
//
//  Fake "other writers'" notes for the Read screen's corkboard. There's
//  still no backend (see PROJECT.md / User.swift's readPublished note),
//  so this is a fixed pool of sample writing standing in for a real
//  community feed — ported from the "Writing" branch's read-another-logic
//  prototype, kept as explicitly-placeholder content rather than the
//  user's own posts.
//
//  Each note's `id` is its fixed index into `all`, not a freshly
//  generated UUID. That matters: the original prototype constructed a
//  brand-new random-UUID entry on every shake, which silently orphaned
//  any bookmark the moment the board reshuffled (the bookmarked ID no
//  longer matched anything). Keying by a stable pool index instead means
//  User's bookmark/read tracking survives reshuffling to a different
//  random batch.
//

import Foundation

struct SampleNote: Identifiable, Hashable {
    let id: Int
    let body: String
    let prompt: String
    let emotionData: String
    let createdAt: Date

    /// Mirrors Post.promptEmotions / PromptData.emotions — same
    /// comma-separated-string convention, so sticky cards can render
    /// sample-note pills with identical logic to real Post pills.
    var emotions: [String] {
        emotionData
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
            .filter { !$0.isEmpty }
    }
}

enum SampleNoteBank {
    /// Cycled across the pool below so each sample note carries a prompt
    /// + emotion pair in AIEmotions' own voice — reusing PromptManager's
    /// fallback bank verbatim — rather than the old Writing branch's
    /// unrelated static prompt list (which also had no emotion data).
    private static let promptPairs: [(text: String, emotionData: String)] = [
        ("Chasing fireflies through fog", "nostalgia, wonder"),
        ("Unpacking a stranger's suitcase", "curiosity, unease"),
        ("Whispering to an empty room", "loneliness, comfort"),
        ("Folding yesterday's letters", "grief, tenderness"),
        ("Racing a closing door", "urgency, hope"),
        ("Planting a borrowed garden", "patience, optimism"),
    ]

    private static let bodies: [String] = [
        """
        I remember the summer my grandfather taught me how to catch fireflies. We'd wait until the sky turned that particular shade of indigo — not quite night, not quite day — and walk barefoot through the wet grass behind his house. He never rushed. That was the thing about him. The world could be falling apart and he'd still stop to watch a spider spin its web.

        He had this mason jar with holes poked into the tin lid, rusty from years of use. "You don't chase them," he told me. "You let them come to you. Hold still. Be patient. They're attracted to the quiet." I didn't understand what he meant at six years old. I understand it now, at thirty-two, sitting in an apartment in a city that never stops humming.

        The fog would roll in from the lake around nine o'clock, thick and silver, turning the yard into something out of a fairy tale. The fireflies looked like tiny lanterns floating through smoke. My grandmother would watch from the kitchen window, drying dishes with a towel that had strawberries printed on it.

        "Five more minutes," he'd whisper, like we were getting away with something. Maybe those five minutes were stolen from the ordinary world and placed somewhere sacred — a pocket of time that belonged only to us.

        He died in November, when there were no fireflies. Just cold rain and bare trees and a silence that felt nothing like the quiet he'd taught me to love. I stood at the edge of his yard one last time, holding that mason jar, waiting for something I couldn't explain.

        Nothing came. But I kept the jar.

        Years later, I took my daughter to that same yard. The house belongs to strangers now, but the grass is the same, and the lake still sends its fog at nine o'clock. She's four, and she runs after the lights with both hands open, laughing when they disappear between her fingers.

        I don't correct her. She'll learn patience in her own time, the way we all do — through loss, through waiting, through fog. For now, I just watch her run, hold the jar, and remember.
        """,

        """
        The rain tapped against the window like tiny fingers asking to come in. I sat with my tea, watching the world blur into watercolor while cars moved slowly through the street below. Everyone seemed to have somewhere important to be, even though the weather had turned the whole city into a gray photograph.

        I used to love rainy afternoons because they gave me permission to stay inside. There was something comforting about hearing water against glass while knowing I didn't have to participate in whatever was happening outside. I could read, sleep, listen to music, or simply sit there and let time pass without feeling guilty about it.

        That afternoon, however, I kept thinking about the last rainy day we spent together. You had forgotten your umbrella, so you stood underneath mine even though it was too small for two people. Your shoulder was completely soaked, and you kept laughing every time I apologized.

        We walked three blocks like that, bumping into each other with every step. It wasn't romantic in the way movies make romance look. There was no perfect soundtrack or dramatic confession. There was just rain, cold fingers, wet shoes, and two people trying not to smile too much.

        I haven't used that umbrella since you left. It is still hanging beside the front door, slightly bent from that afternoon.

        Sometimes I think I'll throw it away. Then it rains, and I remember why I never do.
        """,

        """
        Sometimes I wonder if the stars remember us the way we remember them — distant, bright, full of stories we'll never fully understand. When I was younger, I thought every star had a purpose. My mother told me that people used to navigate by them, and somehow that made the night sky feel like a map designed specifically for lost people.

        I spent countless nights lying on the roof of our house, trying to recognize constellations. I was terrible at it. I could never remember which group of stars was supposed to look like a hunter or a bear or a person carrying a cup.

        What I did remember was the feeling.

        The world became quieter up there. The arguments downstairs disappeared. Homework stopped mattering. Tomorrow's problems became distant and insignificant. For a few minutes, I could pretend that everything was exactly where it belonged.

        Years later, I moved to a city where the stars are almost invisible. There are too many buildings, too many streetlights, too much noise. The first time I looked up and saw only a handful of faint dots, I felt strangely disappointed.

        So I started visiting the outskirts whenever I could. I drive until the buildings disappear, park somewhere dark, and sit on the hood of my car.

        The stars are still there.

        Maybe that is the comforting part. They were there when I was a child, they are here now, and they will probably still be there when I've forgotten most of the things I currently think are important.
        """,

        """
        She left the letter on the kitchen table, folded twice, smelling faintly of lavender. He didn't open it until spring.

        For three months, the envelope stayed exactly where she had left it. Every morning he would see it while making coffee. Every evening he would notice it again while washing the dishes. Eventually, the envelope became part of the kitchen itself, like the clock above the refrigerator or the small crack in the tile near the sink.

        His friends told him to open it.

        His sister told him to burn it.

        His mother told him that whatever was inside probably wouldn't change anything.

        He wasn't afraid of what the letter said. He was afraid of what opening it would mean.

        As long as the envelope remained sealed, there was still a possibility that the letter contained something he desperately wanted to hear. An apology. An explanation. A request to come back. Maybe even three simple words that could somehow undo everything that had happened.

        But unopened things have a strange power. They allow us to live inside possibilities instead of facts.

        When spring finally arrived, sunlight reached the kitchen table for the first time in months. He made coffee, sat down, and picked up the envelope.

        The paper inside contained only six sentences.

        None of them asked him to stay.

        None of them asked him to leave.

        She simply wished him a life that felt like his own.

        He read the letter twice, then folded it carefully and placed it inside the drawer.

        For the first time in three months, he opened the front door.
        """,

        """
        The old bookshop on Fifth Street closed today. Twenty years of dog-eared pages and whispered recommendations, gone.

        I remember walking into that shop for the first time when I was thirteen. I had no idea what I wanted to read. I only knew that I was bored and that my parents had dropped me off while they went somewhere else.

        The owner noticed me wandering between the shelves.

        "Looking for anything?"

        I shrugged.

        He smiled and handed me a battered mystery novel. "Then start with something you don't understand."

        I bought it with the money I had saved for snacks.

        I finished the book two days later.

        After that, the shop became a kind of refuge. I went there after school when I didn't want to go home yet. I went there when my friends were busy. I went there after my first breakup, when I needed somewhere quiet enough to be miserable without anyone asking questions.

        The owner remembered what I liked. Somehow, he always knew which books I needed before I did.

        Today I stood outside while workers carried the final boxes through the door. The sign had already been removed, leaving a clean rectangle on the wall where the letters had protected the paint from the sun.

        I wanted to tell him what that place had meant to me.

        Instead, I simply thanked him for the books.

        He nodded as if he understood.

        Maybe some places don't disappear completely when they close. Maybe they simply move inside the people who needed them.
        """,

        """
        I learned to swim in words before I learned to swim in water. The page was always kinder than the ocean.

        When I was a child, my parents took me to the beach every summer. They would stand waist-deep in the water and call for me to come closer, but I never did. I hated the feeling of not knowing what was beneath my feet.

        Books were different.

        In books, I could enter deep oceans without getting wet. I could climb mountains without feeling cold. I could travel to countries I couldn't pronounce and become friends with people who had never existed.

        Whenever life became overwhelming, I disappeared into stories.

        At first, I thought this meant I was running away.

        Maybe I was.

        But years later, I realized that stories didn't teach me to avoid reality. They taught me how to understand it. Every character carried some version of fear, loneliness, ambition, regret, or hope. The more I read about other people, the easier it became to recognize those emotions in myself.

        Eventually, I learned how to swim.

        I was twenty-four when I finally walked into the ocean without holding anyone's hand. The water was colder than I expected. The waves pushed me backward, and for a moment I panicked.

        Then I remembered something I had read years earlier.

        You don't have to defeat the water.

        You only have to learn how to move with it.

        I think that applies to more than swimming.
        """,

        """
        There's a kind of silence that only exists at 3 AM — not empty, but full, like a breath held too long.

        The apartment sounds different at that hour. The refrigerator becomes strangely loud. Pipes knock somewhere inside the walls. A distant motorcycle passes through the street, its engine fading until there is nothing left but the hum of electricity.

        I used to hate being awake at three.

        Now I sometimes look forward to it.

        During the day, there are too many things competing for attention. Messages arrive. People ask questions. Phones vibrate. There are deadlines and conversations and expectations. At three in the morning, none of that feels quite as urgent.

        One night I sat beside the window and watched someone in the opposite building turn on their kitchen light.

        I wondered who they were.

        Maybe they were studying. Maybe they couldn't sleep. Maybe they had just received bad news. Maybe they were making tea for someone they loved.

        We were complete strangers, separated by glass and concrete, yet somehow sharing the same sleepless hour.

        The light stayed on for twenty minutes.

        Then it disappeared.

        I stayed by the window a little longer.

        Sometimes loneliness feels less painful when you remember that somewhere, someone else is awake too.
        """,

        """
        My grandmother's hands told stories her mouth never did. Each wrinkle was a chapter, each scar a plot twist.

        She had a small scar across her thumb from an accident she refused to explain properly. Whenever I asked about it, she would wave her hand and say, "That was a long time ago."

        Her hands were always busy.

        She kneaded dough before sunrise. She folded clothes while watching television. She repaired loose buttons without needing glasses. When she cooked, she never measured anything. She simply looked at the ingredients and somehow knew.

        As a child, I thought everyone else's grandmother had hands like hers.

        It wasn't until I grew older that I realized how much history those hands carried.

        They had held babies, washed dishes, planted flowers, written letters, opened difficult doors, and wiped tears from children's faces.

        Near the end of her life, her hands became much quieter.

        I remember sitting beside her bed and holding one of them. It felt smaller than I remembered.

        She squeezed my fingers.

        "You're getting too serious," she whispered.

        I laughed.

        "And you're getting too old."

        She smiled.

        "That's what happens when you keep waiting for tomorrow."

        I didn't understand then.

        I think I do now.
        """,

        """
        We built a fort out of cardboard boxes and called it a castle. For one afternoon, we were kings of something real.

        The boxes came from the refrigerator our parents had bought that week. They were enormous compared to us, so we dragged them into the living room and spent hours cutting windows into the sides.

        We made flags from old shirts.

        We used blankets as curtains.

        We drew a complicated map of our imaginary kingdom on the floor.

        There was a dragon behind the sofa, a secret tunnel underneath the dining table, and a dangerous forest that began approximately three steps from the television.

        Nobody laughed at us.

        Not even our parents.

        They brought us snacks and pretended to knock before entering our kingdom.

        "Your Majesty," my mother would say.

        "State your business," I would answer.

        We believed the game would last forever.

        Of course, it didn't.

        The cardboard eventually became soft and bent. The blankets were needed for laundry. The living room had to become a living room again.

        Years later, I found an old photograph of that fort.

        I stared at it for a long time.

        We looked ridiculous.

        We also looked completely happy.

        I think adulthood is partly the process of forgetting how easy it once was to build a kingdom out of almost nothing.
        """,

        """
        The coffee shop where we first met turned into a parking lot. Progress, they called it. I called it erasure.

        I hadn't visited the place in years, but I still remembered the exact table where we sat. It was near the window, underneath a crooked painting of a blue bicycle.

        You spilled coffee on the table.

        I laughed.

        You apologized three times.

        Then we started talking.

        We talked until the staff turned off half the lights around us. Neither of us noticed the time passing.

        It became our place after that.

        We celebrated birthdays there. We studied there. We argued there. We made plans we were convinced would actually happen.

        Eventually, we stopped going.

        Eventually, we stopped talking.

        I thought I had forgotten the place until I drove past it last week.

        There was no coffee shop anymore.

        Just painted parking lines and a metal sign announcing a new development.

        I parked anyway.

        I stood there for several minutes, trying to match the empty pavement to the memory in my head.

        Nothing looked familiar.

        Maybe that is what happens to old memories. They survive inside us long after the places that created them disappear.

        I drove away without taking a photograph.

        Some places are better remembered than preserved.
        """,

        """
        I keep a jar of sea glass on my desk. Each piece was sharp once, before the ocean taught it patience.

        I started collecting them when I was seventeen. Back then, I thought every piece was treasure. Green, blue, brown, clear — I didn't care what color it was as long as the edges were smooth.

        I liked imagining where each piece had come from.

        A bottle.

        A window.

        Something thrown away by someone who never imagined it would eventually become beautiful.

        The ocean doesn't transform things quickly.

        It takes years.

        Sometimes decades.

        Waves push objects against rocks again and again until the sharpness disappears.

        I think people are like that too.

        There were parts of me I used to hate. Things I wished I could erase. Mistakes I replayed until they felt like permanent evidence that I wasn't good enough.

        Time didn't erase those things.

        It softened them.

        Eventually, I could touch those memories without cutting myself open.

        That's why I keep the jar on my desk.

        Whenever I feel impatient about becoming someone better, I look at those pieces of glass.

        They remind me that transformation doesn't always look dramatic.

        Sometimes it is simply surviving the next wave.
        """,

        """
        He played the same song every morning. Not because he loved it, but because she used to hum it in her sleep.

        The song wasn't particularly beautiful. It was an old melody with a simple piano line and lyrics he had never paid much attention to.

        She loved it anyway.

        Before she became sick, she used to sing it while making breakfast. Sometimes she remembered all the words. Sometimes she invented new ones.

        He would tease her about it.

        She would throw a towel at him.

        After she died, the apartment became painfully quiet.

        For several weeks, he couldn't listen to music at all.

        Then one morning, without thinking, he played that song.

        He expected the grief to crush him.

        Instead, something unexpected happened.

        He smiled.

        Not because he wasn't sad.

        Because for three minutes, the apartment sounded like her again.

        He still plays the song every morning.

        Some people might think he's refusing to move on.

        Maybe they are right.

        But he has learned that moving forward doesn't necessarily mean leaving everything behind.

        Sometimes you carry a song with you.
        """,

        """
        The dictionary defines home as a place of residence. It says nothing about the ache of returning to one that no longer fits.

        I went back last weekend.

        The house looked smaller than I remembered. The hallway seemed narrower. The kitchen counter that once felt impossibly tall reached only to my waist.

        There were new curtains.

        The walls had been painted.

        Someone had planted flowers where my parents used to park the old car.

        Everything was familiar and completely wrong.

        I walked into my childhood bedroom and found another person's belongings. A desk covered in notebooks. Posters I didn't recognize. Clothes hanging inside the closet.

        I felt strangely offended.

        As if the room had betrayed me.

        Then I realized how ridiculous that was.

        The room belonged to someone else now.

        I was the one who had left.

        We spend so much of our lives believing that places wait for us. They don't.

        Houses change.

        Streets change.

        People change.

        Even the memories we carry change shape when we look at them from a different age.

        I stood outside before leaving and took one last look at the windows.

        It wasn't my home anymore.

        But for a little while, it had been.

        Maybe that's enough.
        """,

        """
        I found a photograph of us laughing, and I couldn't remember what was so funny. That terrified me more than forgetting your face.

        The photograph was hidden inside an old notebook. I found it while cleaning my room, tucked between pages filled with notes I hadn't read in years.

        There we were.

        Sitting on the floor.

        Smiling at something outside the frame.

        You were holding a mug with both hands, and I was making the ridiculous expression you always said made me look twelve years old.

        I remembered the room.

        I remembered the couch.

        I remembered what you were wearing.

        But I couldn't remember the joke.

        For some reason, that tiny missing piece hurt more than everything else.

        Memories don't disappear all at once.

        They leave quietly.

        First the small details.

        Then the sound of someone's laugh.

        Then the exact shape of their handwriting.

        Eventually, you are left holding a photograph and trying to reconstruct a life from fragments.

        I put the photograph back inside the notebook.

        Maybe forgetting isn't always betrayal.

        Maybe it's simply what minds do when they are trying to make room for tomorrow.
        """,

        """
        The taxi driver told me his whole life story in twelve blocks. Somewhere between 3rd and 7th Avenue, I forgot my own sadness.

        He started talking before I had even finished closing the door.

        His daughter had just graduated.

        His brother lived overseas.

        He had once wanted to become a musician but ended up driving a taxi because life had other plans.

        I mostly listened.

        Every few minutes, he checked the mirror and asked if I was okay.

        I kept saying yes.

        He clearly didn't believe me.

        When we stopped at a red light, he told me that people always think their current problems are permanent.

        "They're not," he said. "Nothing stays exactly the same."

        I asked him how he knew.

        He laughed.

        "Because I'm old."

        By the time we reached my destination, I had forgotten why I had been crying before getting into the car.

        I paid him.

        He refused the extra tip.

        "Keep it," he said. "Buy yourself something tomorrow."

        I watched his car disappear into traffic.

        I never learned his name.

        But for twelve blocks, a stranger reminded me that my life was larger than the thing hurting me that night.
        """,

        """
        She painted sunsets the way other people breathe — effortlessly, endlessly, as if the sky owed her its palette.

        Her apartment was filled with paintings.

        Some were bright orange and violent red.

        Others were almost completely gray.

        I once asked why she painted the same subject so many times.

        "Because it never looks the same," she said.

        I didn't understand.

        A sunset was a sunset.

        Then she showed me paintings from different years.

        Suddenly I saw it.

        The colors changed depending on what she had been feeling.

        The happiest painting was almost unbearable to look at.

        The saddest one was surprisingly gentle.

        She told me that people often try to hide their emotions because they think feelings make them weak.

        "Paint them," she said. "At least then they'll have somewhere to go."

        I never became a painter.

        But I started writing.

        Whenever I feel something I can't explain, I put it on a page.

        Maybe that's my version of painting sunsets.

        Maybe we all need somewhere to put the things we don't know how to carry.
        """,

        """
        There's a tree in my old backyard that still has my initials carved into it. I wonder if it remembers the boy who held the knife.

        I was eleven when I carved those letters.

        I thought they would last forever.

        The tree was already taller than our house, and I imagined that someday it would become enormous while my initials remained exactly where I had left them.

        Years passed.

        My family moved.

        I grew up.

        I forgot about the tree.

        Then, twenty years later, I visited the neighborhood again.

        The tree was still there.

        My initials were barely visible beneath a layer of new bark.

        I touched them with my fingers.

        It felt strange to meet an older version of myself through something I had left behind.

        I remembered the boy I was.

        He was impatient.

        He thought everything would last forever.

        He believed growing older meant becoming someone completely different.

        Now I understand that adulthood is stranger than that.

        We don't replace our younger selves.

        We carry them.

        The impatient child.

        The frightened teenager.

        The person who made mistakes.

        They all remain somewhere inside us.

        The tree didn't remember my name perfectly.

        Neither do I.

        But it remembered enough.
        """,

        """
        The last voicemail she left me is still on my phone. I can't listen to it, but I'll never delete it.

        It is only forty-seven seconds long.

        I know because I have looked at the duration hundreds of times.

        I don't remember exactly what she said.

        That's the cruel part.

        I remember the sound of her breathing before she spoke.

        I remember the tiny pause halfway through the message.

        I remember her laughing at the end.

        But the words themselves have become blurry.

        Sometimes I think I could listen to it and finally understand something.

        Other times I think listening would destroy the fragile version of her memory that I have managed to preserve.

        So the voicemail stays there.

        Buried among delivery notifications, missed calls, and old conversations.

        Technology was never supposed to preserve grief.

        Yet somehow it does.

        A few seconds of someone's voice can outlive years of photographs.

        Maybe one day I'll play it.

        Maybe I won't.

        For now, knowing that her voice is still somewhere inside that little rectangle is strangely comforting.
        """,

        """
        We used to measure summer by the height of the sunflowers. This year, nobody planted any.

        When I was a child, the garden behind our house was impossible to ignore.

        Sunflowers stood taller than me.

        Tomatoes grew in tangled rows.

        My father built a small wooden fence that never stayed straight because the ground was uneven.

        Every summer seemed endless.

        We thought the garden would always be there.

        Then my parents got older.

        The garden became harder to maintain.

        One year, fewer flowers appeared.

        The next year, none.

        This summer I visited again.

        The soil was still there, but the garden had become a patch of grass.

        I stood in the middle of it and tried to remember exactly how tall the sunflowers had been.

        I couldn't.

        Memory exaggerates things.

        Perhaps they weren't as enormous as I remember.

        Perhaps childhood simply makes everything look larger.

        I don't know.

        But I know I miss them.

        Sometimes grief isn't about losing a person.

        Sometimes it is about losing a version of the world that only existed while you were young.
        """,

        """
        I wrote your name in the sand and watched the tide take it. The ocean doesn't care about permanence either.

        I used to think writing someone's name somewhere beautiful made the memory more meaningful.

        On beaches.

        In notebooks.

        On the corners of school desks.

        Inside the margins of books.

        I thought permanence was the goal.

        Then the waves came.

        The letters disappeared in seconds.

        At first I felt disappointed.

        Then I laughed.

        Maybe the point was never to make the name stay.

        Maybe the point was that, for a brief moment, it existed.

        The same could be said about people.

        We arrive.

        We leave marks.

        We change things.

        Then eventually the world moves on.

        That sounds sad until you realize how beautiful it is.

        Nothing needs to last forever to matter.

        A conversation can change you in ten minutes.

        A song can belong to one particular summer.

        A stranger can say one sentence that you remember for twenty years.

        The tide erases the name.

        It doesn't erase the fact that I wrote it.
        """,

        """
        The library smelled of dust and possibility. Every shelf was a door, every book a key to somewhere I'd never been.

        I spent most afternoons there during my final year of school.

        I was supposed to be studying.

        Usually, I wasn't.

        Instead, I wandered between shelves and opened books at random.

        Some were boring.

        Some were impossible to understand.

        Some changed the way I looked at the world.

        There was an elderly librarian who always seemed to know when I was avoiding my homework.

        "Looking for something?" she'd ask.

        "No."

        "Good. Those are usually the best things to find."

        I didn't understand what she meant until years later.

        We spend so much time looking for exactly what we think we need.

        The right career.

        The right person.

        The right answer.

        Sometimes the most important things arrive because we weren't looking for them.

        I still visit libraries whenever I travel.

        They remind me that there are thousands of lives happening inside other people's heads.

        All you have to do is open a door.
        """,

        """
        My father's watch stopped the day he did. I wear it anyway — a reminder that some things outlast the hands that wound them.

        The watch was never expensive.

        The leather strap was cracked.

        The glass had a tiny scratch near the number three.

        He wore it every day for as long as I could remember.

        After he died, my mother gave it to me.

        I tried winding it.

        Nothing happened.

        I took it to a repair shop, and the man behind the counter told me it could probably be fixed.

        I said no.

        He looked confused.

        "Why?"

        I couldn't explain it.

        The stopped hands felt right.

        They marked the moment when his time ended, even though mine continued.

        I wear it whenever I have something important to do.

        Job interviews.

        First dates.

        Difficult conversations.

        Whenever I'm afraid, I look down at the watch.

        The hands never move.

        Somehow, that reminds me that I still can.
        """,

        """
        The streetlights came on one by one like tired eyes opening. The city never truly sleeps, it just pretends.

        I walked home after midnight because I didn't want the night to end yet.

        The streets were quieter than usual.

        Restaurants were closing.

        Workers were dragging chairs inside.

        A couple argued quietly outside a convenience store.

        Somewhere above me, someone was playing music through an open window.

        Cities look different when most people are asleep.

        During the day, everything feels urgent.

        At night, the same buildings become anonymous shapes.

        I passed the office where I used to work.

        I passed the apartment where I had my first serious argument with someone I loved.

        I passed the hospital where my mother had once waited for me.

        Every street seemed to contain a version of my past.

        I realized that I had spent years trying to leave certain memories behind.

        But memories don't stay in the places where they happened.

        They travel.

        They follow us home.

        Maybe growing older is learning to walk beside them instead of constantly trying to outrun them.
        """,

        """
        I pressed a wildflower between the pages of your favourite book. You'll find it someday, and maybe you'll think of me.

        I chose the flower because it reminded me of you.

        Small.

        Bright.

        Easy to overlook if you weren't paying attention.

        I found it growing beside the train station after you left.

        I almost stepped over it.

        Then I remembered how you always stopped to notice tiny things.

        A bird sitting on a wire.

        A cracked window reflecting sunlight.

        A strange cloud that looked like an animal.

        You had a talent for making ordinary things feel important.

        I put the flower inside your book because I didn't know how else to say goodbye.

        Maybe you'll never find it.

        Maybe you'll sell the book.

        Maybe you'll read the page years from now and wonder who put it there.

        That's okay.

        Not every message needs to reach its destination.

        Sometimes writing something down is enough.

        Sometimes the act of saying goodbye is more important than being heard.
        """,

        """
        The train pulled away and I didn't wave. Sometimes goodbye is just standing still while everything else moves.

        I watched the windows until I could no longer tell which one was yours.

        People always imagine goodbyes as dramatic moments.

        Someone cries.

        Someone runs after the train.

        Someone says exactly the right thing at exactly the right time.

        Mine wasn't like that.

        We stood on the platform and talked about ordinary things.

        The weather.

        Work.

        What we might eat later.

        Neither of us mentioned that you were leaving.

        When the announcement came, you hugged me.

        It lasted three seconds.

        Maybe four.

        Then you walked onto the train.

        I wanted to say something meaningful.

        Nothing came.

        So I stayed silent.

        The train began moving.

        You looked through the window.

        I looked back.

        I didn't wave.

        I don't know why.

        Perhaps some goodbyes are too large for gestures.

        Perhaps standing there and watching was enough.
        """,

        """
        She collected words the way magpies collect shiny things — greedily, lovingly, with no regard for what's practical.

        Her notebooks were everywhere.

        Beside the bed.

        Under the couch.

        Inside kitchen drawers.

        She wrote down words she liked even when she didn't know how to use them.

        "Why do you keep these?" I asked.

        She shrugged.

        "Because I don't want beautiful things to disappear."

        I thought that was ridiculous.

        Words aren't objects.

        They can't disappear.

        Then I started noticing how quickly language changes.

        Expressions become outdated.

        Names stop being spoken.

        Words that once carried enormous meaning become strange and unfamiliar.

        She was collecting little pieces of a disappearing world.

        Years later, I found one of her notebooks.

        Almost every page was filled.

        Some words had definitions.

        Others had tiny sentences beside them.

        A few had only question marks.

        I read the entire notebook.

        At the end, she had written one sentence:

        "Maybe understanding begins with admitting that you don't know."

        I think that might be the most useful definition she ever collected.
        """,

        """
        The kitchen smelled of cinnamon and regret. I was baking her recipe, but it would never taste the same.

        I followed the instructions exactly.

        Same flour.

        Same sugar.

        Same amount of cinnamon.

        Same temperature.

        Same old mixing bowl.

        Somehow, the result was different.

        Too dry.

        Too sweet.

        Not enough of something I couldn't identify.

        I called my mother and asked what I had done wrong.

        She laughed.

        "Nothing."

        "Then why doesn't it taste right?"

        There was a pause.

        "Because you're not her."

        I hated that answer.

        Then I understood it.

        Recipes are rarely just ingredients.

        They are hands.

        Timing.

        Habits.

        Memories.

        Someone knowing exactly when the dough looks right without measuring anything.

        I ate one anyway.

        It wasn't hers.

        But it was mine.

        Maybe that is what we do with the things people leave us.

        We try to recreate them.

        Eventually, we stop trying to make them identical.

        We make something new.
        """,

        """
        I counted the cracks in the ceiling and imagined they were rivers on a map leading somewhere I'd never go.

        It was one of those nights when sleep refused to arrive.

        I lay flat on my back, staring upward.

        The largest crack began above the window and stretched toward the center of the room.

        I followed it with my eyes.

        It became a river.

        The smaller cracks became tributaries.

        The water traveled across imaginary mountains and disappeared into a sea I invented.

        For a while, I forgot that I was lying in bed.

        I was somewhere else.

        Somewhere quiet.

        Somewhere without unfinished conversations or unanswered messages.

        When morning arrived, the ceiling became a ceiling again.

        The cracks were ugly.

        Ordinary.

        Impossible to mistake for a map.

        But I remembered what they had looked like at three in the morning.

        Sometimes imagination doesn't change the world.

        It changes the few minutes we spend inside it.
        """,

        """
        The old piano in the corner hadn't been tuned in years, but it still knew how to hold a melody hostage.

        Nobody played it anymore.

        The keys were yellow.

        Several were stuck.

        The wood had faded where sunlight reached it through the window.

        Still, whenever I visited my aunt's house, I would sit down and press a few keys.

        The notes sounded terrible.

        She would laugh from the kitchen.

        "You're getting worse."

        "I'm practicing."

        "You've been practicing for fifteen years."

        She was right.

        I never learned how to play properly.

        But I didn't care.

        The piano reminded me of my childhood.

        My mother used to play it on Sunday mornings.

        She wasn't particularly good either.

        She made mistakes constantly.

        Sometimes she would stop halfway through a song and start laughing.

        At the time, I thought music was supposed to be perfect.

        Now I think perfection would have ruined it.

        The mistakes were part of the memory.

        The pauses were part of the song.

        The imperfect notes were what made it ours.
        """,

        """
        We promised to write letters, real ones, with stamps and everything. The first one arrived three months late. The second one never came.

        I still remember buying the stationery.

        We spent almost an hour choosing the right envelopes.

        We joked about becoming old-fashioned correspondents.

        "We'll write every week," you said.

        I believed you.

        The first letter arrived in September.

        I recognized your handwriting immediately.

        You wrote about everything.

        Your new apartment.

        The terrible food.

        The neighbor who played music at midnight.

        A dog you saw every morning.

        None of it was important.

        Somehow, all of it mattered.

        I wrote back the next day.

        Then I waited.

        Weeks passed.

        Months.

        I eventually stopped checking the mailbox.

        Years later, I found my unopened draft letter inside an old drawer.

        I had written it.

        I had sealed it.

        I had even addressed it.

        Somehow, I had never sent it.

        I sat on the floor holding that envelope and laughed.

        Maybe we were both waiting for the other person to prove that the distance didn't matter.

        Neither of us did.

        Some stories end because people stop loving each other.

        Others end because nobody knows how to keep reaching.
        """,

        """
        The fog rolled in like a secret, hiding the harbour and muffling the horns. For one hour, the world was only as big as my front porch.

        I sat outside with a blanket around my shoulders and watched the fog swallow everything.

        The apartment building across the street disappeared first.

        Then the trees.

        Then the road.

        Eventually, even the nearest streetlight became a blurry orange circle.

        I couldn't see very far.

        Strangely, that made me feel safe.

        Most of the time, we are surrounded by information.

        Where everyone is.

        What everyone is doing.

        What happened yesterday.

        What might happen tomorrow.

        That night, none of it mattered.

        I couldn't see the harbour.

        I couldn't see the road.

        I couldn't see beyond the edge of the porch.

        All I had was the chair beneath me, the blanket around my shoulders, and the sound of distant water.

        For once, not knowing what came next didn't feel frightening.

        It felt peaceful.

        Maybe uncertainty isn't always something we need to solve.

        Maybe sometimes we just need to sit inside the fog until it clears.
        """
    ]

    /// The full fixed pool, in stable id order.
    static let all: [SampleNote] = bodies.enumerated().map { index, body in
        let pair = promptPairs[index % promptPairs.count]
        return SampleNote(
            id: index,
            body: body,
            prompt: pair.text,
            emotionData: pair.emotionData,
            createdAt: Calendar.current.date(byAdding: .day, value: -index, to: Date()) ?? Date()
        )
    }

    /// A random subset for one board "batch" — reshuffled on shake. Always
    /// drawn from the same stable-id pool, so a note's identity (and any
    /// bookmark/read state keyed on it) survives moving between batches.
    static func randomBatch(minCount: Int = 12) -> [SampleNote] {
        let shuffled = all.shuffled()
        let count = Int.random(in: min(minCount, shuffled.count)...shuffled.count)
        return Array(shuffled.prefix(count))
    }
}
