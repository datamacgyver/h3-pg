/*
 * Copyright 2018-2019 Bytes & Brains
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

-- ---------- ---------- ---------- ---------- ---------- ---------- ----------
-- Hierarchical Grid Functions (hierarchy.c)
-- ---------- ---------- ---------- ---------- ---------- ---------- ----------

-- Availability: 1.0.0
CREATE OR REPLACE FUNCTION h3_to_parent(h3index, resolution integer DEFAULT -1) RETURNS h3index
    AS 'h3' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
    COMMENT ON FUNCTION h3_to_parent(h3index, resolution integer) IS
'Returns the parent of the given index';

-- Availability: 1.0.0
CREATE OR REPLACE FUNCTION h3_to_children(h3index, resolution integer DEFAULT -1) RETURNS SETOF h3index
    AS 'h3' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
    COMMENT ON FUNCTION h3_to_children(index h3index, resolution integer) IS
'Returns the set of children of the given index';

-- Availability: 3.6.0
CREATE OR REPLACE FUNCTION h3_to_center_child(h3index, resolution integer DEFAULT -1) RETURNS h3index
    AS 'h3' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
    COMMENT ON FUNCTION h3_to_parent(h3index, resolution integer) IS
'Returns the center child (finer) index contained by input index at given resolution';

-- Availability: 0.2.0
CREATE OR REPLACE FUNCTION h3_compact(h3index[]) RETURNS SETOF h3index
    AS 'h3' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
    COMMENT ON FUNCTION h3_compact(h3index[]) IS
'Compacts the given array as best as possible';

-- Availability: 0.2.0
CREATE OR REPLACE FUNCTION h3_uncompact(h3index[], resolution integer DEFAULT -1) RETURNS SETOF h3index
    AS 'h3' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
    COMMENT ON FUNCTION h3_uncompact(h3index[], resolution integer) IS
'Uncompacts the given array at the given resolution. If no resolution is given, then it is chosen as one higher than the highest resolution in the set';

-- ---------- ---------- ---------- ---------- ---------- ---------- ----------
-- Custom Funtions
-- ---------- ---------- ---------- ---------- ---------- ---------- ----------

-- Availability: 1.0.0
CREATE OR REPLACE FUNCTION __h3_to_children_aux(index h3index, resolution integer, current INTEGER) 
    RETURNS SETOF h3index AS $$
    DECLARE 
        retSet h3index[];
        r h3index;
    BEGIN
        IF current = -1 THEN 
            SELECT h3_get_resolution(index) into current;
        END IF;

        IF resolution = -1 THEN 
            SELECT h3_get_resolution(index)+1 into resolution;
        END IF;

        IF current < resolution THEN
            SELECT ARRAY(SELECT h3_to_children(index)) into retSet;
            FOREACH r in ARRAY retSet LOOP
                RETURN QUERY SELECT __h3_to_children_aux(r, resolution, current + 1);
            END LOOP;
        ELSE
            RETURN NEXT index;
        END IF;
    END;$$ LANGUAGE plpgsql;

-- Availability: 1.0.0
CREATE OR REPLACE FUNCTION h3_to_children_slow(index h3index, resolution integer DEFAULT -1) RETURNS SETOF h3index
    AS $$ SELECT __h3_to_children_aux($1, $2, -1) $$ LANGUAGE SQL;
    COMMENT ON FUNCTION h3_to_children_slow(index h3index, resolution integer) IS
'Slower version of H3ToChildren but allocates less memory';

